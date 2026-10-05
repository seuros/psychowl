# frozen_string_literal: true

module Psychowl
  # The language tables shared with the Rust crate. The Rust crate compiles
  # them in; the Ruby engine reads them here, once, at load time.
  #
  # Languages and scripts are referred to by index (their line number in
  # languages.tsv / scripts.tsv), which both engines agree on.
  module Tables
    DIR = File.expand_path('../../ext/psychowl_native/core/data', __dir__)

    # Characters that carry no language information: ASCII controls, spaces,
    # digits and punctuation. A tr-style set for String#count / String#tr.
    STOP_CHARS = "\u0000-@[-`{-~"

    class << self
      def rows(file) = DataFile.lines(File.join(DIR, file)).map { |line| line.split("\t") }

      # Turns literal characters into a String#count set, escaping the
      # characters that have a meaning there.
      def charset(chars) = chars.gsub(/[\\^-]/) { |char| "\\#{char}" }

      def range_charset(ranges)
        ranges.split(',').map do |range|
          low, high = range.split('-').map { |hex| hex.to_i(16).chr(Encoding::UTF_8) }
          high ? "#{charset(low)}-#{charset(high)}" : charset(low)
        end.join
      end
    end

    # [[code, iso639_1, eng_name, name], ...]
    LANGUAGES = rows('languages.tsv').map(&:freeze).freeze
    LANGUAGE_INDEX = LANGUAGES.each_with_index.to_h { |(code, *), index| [code, index] }.freeze

    Script = ::Data.define(:name, :languages, :charset)
    # [Script(name, [language index, ...], String#count set), ...]
    SCRIPTS = rows('scripts.tsv').map do |name, codes, ranges|
      languages = codes == '-' ? [] : codes.split(',').map { |code| LANGUAGE_INDEX.fetch(code) }
      Script.new(name: name.freeze, languages: languages.freeze, charset: range_charset(ranges).freeze)
    end.freeze
    SCRIPT_INDEX = SCRIPTS.each_with_index.to_h { |script, index| [script.name, index] }.freeze

    # {language index => String#count set of its letters}
    ALPHABETS = rows('alphabets.tsv').to_h do |code, letters|
      [LANGUAGE_INDEX.fetch(code), charset(letters).freeze]
    end.freeze

    # {language index => [trigram, ...]} most frequent first, " " for a word boundary.
    TRIGRAMS = Dir[File.join(DIR, 'trigrams', '*.txt')].to_h do |path|
      code = File.basename(path, '.txt')
      [LANGUAGE_INDEX.fetch(code), DataFile.lines(path).map { |line| line.tr('_', ' ').freeze }.freeze]
    end.freeze

    HAN = SCRIPT_INDEX.fetch('Han')
    HIRAGANA = SCRIPT_INDEX.fetch('Hiragana')
    KATAKANA = SCRIPT_INDEX.fetch('Katakana')
    CMN = LANGUAGE_INDEX['cmn']
    JPN = LANGUAGE_INDEX['jpn']
  end
end
