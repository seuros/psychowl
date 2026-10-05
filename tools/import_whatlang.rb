#!/usr/bin/env ruby
# frozen_string_literal: true

# Ports language tables from whatlang 0.18 (MIT, github.com/greyblake/whatlang-rs)
# into psychowl's data files. A dev tool, not a dependency.
#
#   WHATLANG_SRC=~/.cargo/registry/src/*/whatlang-0.18.0/src \
#     ruby tools/import_whatlang.rb ara cmn deu eng fra ita jpn por rus spa
#
# Languages are merged into the existing files, so waves accumulate.

require 'fileutils'
require_relative 'support'

SRC = ENV.fetch('WHATLANG_SRC') { abort "set WHATLANG_SRC to whatlang's src/ directory" }
DATA = DataTools::DATA
CODES = ARGV.map(&:downcase).uniq
abort 'usage: import_whatlang.rb CODE...' if CODES.empty?

ISO639_1 = {
  'afr' => 'af', 'aka' => 'ak', 'amh' => 'am', 'ara' => 'ar', 'aze' => 'az', 'bel' => 'be',
  'ben' => 'bn', 'bul' => 'bg', 'cat' => 'ca', 'ces' => 'cs', 'cmn' => 'zh', 'cym' => 'cy',
  'dan' => 'da', 'deu' => 'de', 'ell' => 'el', 'eng' => 'en', 'epo' => 'eo', 'est' => 'et',
  'fin' => 'fi', 'fra' => 'fr', 'guj' => 'gu', 'heb' => 'he', 'hin' => 'hi', 'hrv' => 'hr',
  'hun' => 'hu', 'hye' => 'hy', 'ind' => 'id', 'ita' => 'it', 'jav' => 'jv', 'jpn' => 'ja',
  'kan' => 'kn', 'kat' => 'ka', 'khm' => 'km', 'kor' => 'ko', 'lat' => 'la', 'lav' => 'lv',
  'lit' => 'lt', 'mal' => 'ml', 'mar' => 'mr', 'mkd' => 'mk', 'mya' => 'my', 'nep' => 'ne',
  'nld' => 'nl', 'nob' => 'nb', 'ori' => 'or', 'pan' => 'pa', 'pes' => 'fa', 'pol' => 'pl',
  'por' => 'pt', 'ron' => 'ro', 'rus' => 'ru', 'sin' => 'si', 'slk' => 'sk', 'slv' => 'sl',
  'sna' => 'sn', 'spa' => 'es', 'srp' => 'sr', 'swe' => 'sv', 'tam' => 'ta', 'tel' => 'te',
  'tgl' => 'tl', 'tha' => 'th', 'tuk' => 'tk', 'tur' => 'tr', 'ukr' => 'uk', 'urd' => 'ur',
  'uzb' => 'uz', 'vie' => 'vi', 'yid' => 'yi', 'zul' => 'zu'
}.freeze

# Script check order in whatlang's detector; psychowl uses it as the
# canonical script order (and tie-break priority). "Mandarin" is renamed
# to its Unicode name, "Han".
SCRIPTS = %w[
  latin cyrillic arabic mandarin devanagari hebrew ethiopic georgian bengali
  hangul hiragana katakana greek kannada tamil thai gujarati gurmukhi telugu
  malayalam oriya myanmar sinhala khmer armenian
].freeze

def read(path) = File.read(File.join(SRC, path))

def rust_char(literal)
  case literal
  when /\A\\u\{(\h+)\}\z/ then Regexp.last_match(1).hex.chr(Encoding::UTF_8)
  when "\\'" then "'"
  when '\\\\' then '\\'
  else literal
  end
end

def match_table(source, function)
  body = source[/fn #{function}\b.*?\n\}/m] or abort "#{function} not found"
  body.scan(/Lang::(\w+) => "([^"]*)"/).to_h { |variant, value| [variant.downcase, value] }
end

lang_source = read('lang.rs')
codes = match_table(lang_source, 'lang_to_code')
names = match_table(lang_source, 'lang_to_name')
eng_names = match_table(lang_source, 'lang_to_eng_name')
variant_for = codes.invert

unknown = CODES - codes.values
abort "unknown whatlang codes: #{unknown.join(', ')}" unless unknown.empty?

profiles = {}
read('trigrams/profiles.rs').scan(/\(\s*Lang::(\w+),\s*&\[(.*?)\],\s*\)/m) do |variant, body|
  char = /'((?:\\u\{\h+\}|\\.|[^'\\]))'/
  trigrams = body.scan(/Trigram\(#{char}, #{char}, #{char}\)/).map do |chars|
    chars.map { rust_char(it) }.join
  end
  profiles[codes.fetch(variant.downcase)] = trigrams
end

alphabets = {}
%w[alphabets/latin.rs alphabets/cyrillic.rs].each do |path|
  read(path).scan(/const ([A-Z]{3}): &str =\s*"([^"]*)";/) do |variant, letters|
    alphabets[codes.fetch(variant.downcase)] = letters
  end
end

chars_source = read('scripts/chars.rs')
ranges = SCRIPTS.to_h do |script|
  body = chars_source[/fn is_#{script}\(ch: char\) -> bool \{(.*?)\n\}/m, 1] or abort "is_#{script} not found"
  char = /'((?:\\u\{\h+\}|[^'\\]))'/
  list = body.scan(/#{char}(?:\.\.=#{char})?/).map do |lo, hi|
    lo = rust_char(lo).ord
    [lo, hi ? rust_char(hi).ord : lo]
  end
  [script, list]
end

# whatlang's Latin range U+1D00..U+1D7F swallows two Cyrillic letters; split
# it so every code point belongs to exactly one script.
cyrillic_points = ranges['cyrillic'].select { |lo, hi| lo == hi }.map(&:first)
ranges['latin'] = ranges['latin'].flat_map do |lo, hi|
  inside = cyrillic_points.grep(lo..hi).sort
  next [[lo, hi]] if inside.empty?

  pieces = []
  start = lo
  inside.each do |point|
    pieces << [start, point - 1] if point > start
    start = point + 1
  end
  pieces << [start, hi] if start <= hi
  pieces
end

all_ranges = ranges.flat_map { |script, list| list.map { |lo, hi| [lo, hi, script] } }.sort
all_ranges.each_cons(2) do |(_, hi, a), (lo, _, b)|
  abort "overlapping script ranges: #{a} and #{b} at U+#{lo.to_s(16)}" if lo <= hi
end

mapping_source = read('scripts/lang_mapping.rs')
script_langs = SCRIPTS.to_h do |script|
  const = { 'latin' => 'LATIN_LANGS', 'cyrillic' => 'CYRILLIC_LANGS', 'arabic' => 'ARABIC_LANGS',
            'devanagari' => 'DEVANAGARI_LANGS', 'hebrew' => 'HEBREW_LANGS' }[script]
  langs =
    if const
      mapping_source[/const #{const}: \[Lang; \d+\] = \[(.*?)\];/m, 1].scan(/Lang::(\w+)/).flatten
    else
      arm = mapping_source[/Script::#{script.capitalize}(?: \| Script::\w+)? => &\[(.*?)\]/, 1] ||
            mapping_source[/Script::\w+ \| Script::#{script.capitalize} => &\[(.*?)\]/, 1]
      arm.scan(/Lang::(\w+)/).flatten
    end
  [script, langs.map { codes.fetch(it.downcase) }]
end

def read_tsv(path)
  return [] unless File.exist?(path)

  DataTools.data_lines(path).map { it.split("\t") }
end

def write_tsv(path, header, rows)
  body = rows.map { it.join("\t") }.join("\n")
  File.write(path, "#{header}#{body}\n")
end

FileUtils.mkdir_p(File.join(DATA, 'trigrams'))

languages_path = File.join(DATA, 'languages.tsv')
languages = read_tsv(languages_path).to_h { |row| [row[0], row] }
CODES.each do |code|
  variant = variant_for.fetch(code)
  languages[code] = [code, ISO639_1.fetch(code), eng_names.fetch(variant), names.fetch(variant)]
end
write_tsv(languages_path, <<~TSV, languages.keys.sort.map { languages[it] })
  # Supported languages, sorted by code. Line order defines language indices.
  # code (ISO 639-3)\tISO 639-1\tEnglish name\tnative name
TSV

supported = languages.keys
script_rows = SCRIPTS.map do |script|
  name = script == 'mandarin' ? 'Han' : script.capitalize
  langs = script_langs.fetch(script)
  langs |= ['jpn'] if script == 'mandarin'
  langs &= supported
  hex = ranges.fetch(script).map { |lo, hi| lo == hi ? format('%04X', lo) : format('%04X-%04X', lo, hi) }
  [name, langs.empty? ? '-' : langs.sort.join(','), hex.join(',')]
end
write_tsv(File.join(DATA, 'scripts.tsv'), <<~TSV, script_rows)
  # Writing systems in detection priority order (ties go to the earlier one).
  # Code point ranges are disjoint. "-" means no supported language yet.
  # name\tlanguages\tranges (hex, inclusive)
TSV

alphabets_path = File.join(DATA, 'alphabets.tsv')
known_alphabets = read_tsv(alphabets_path).to_h { |code, letters| [code, letters] }
CODES.each { |code| known_alphabets[code] = alphabets[code] if alphabets.key?(code) }
write_tsv(alphabets_path, <<~TSV, known_alphabets.sort)
  # Letters commonly used by a language, lowercase. Only used for scripts
  # shared by several languages (Latin, Cyrillic).
  # code\tletters
TSV

CODES.each do |code|
  trigrams = profiles[code] or next
  invalid = trigrams.reject { |trigram| trigram.length == 3 && !trigram.match?(/[_#\t\n]|[^ \S]/) }
  abort "#{code}: trigrams cannot be encoded: #{invalid.inspect}" unless invalid.empty?

  DataTools.write_profile(code, trigrams, 'Ported from whatlang 0.18.0 (MIT), see ../LICENSE-whatlang.')
end

puts "languages: #{languages.keys.sort.join(' ')}"
puts "profiles:  #{CODES.select { profiles.key?(it) }.join(' ')}"
puts "alphabets: #{CODES.select { alphabets.key?(it) }.join(' ')}"
