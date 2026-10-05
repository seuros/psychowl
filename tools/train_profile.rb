#!/usr/bin/env ruby
# frozen_string_literal: true

# Builds a language's trigram profile from a plain-text corpus, using the
# exact trigram extraction both engines use at detection time.
#
#   ruby tools/train_profile.rb eng                 # reads corpus/eng.txt
#   ruby tools/train_profile.rb eng path/to/text.txt
#
# Writes ext/psychowl_native/core/data/trigrams/<code>.txt and prints the
# letters the corpus uses, as a starting point for alphabets.tsv.

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
ENV['DISABLE_PSYCHOWL_NATIVE'] = '1'
require 'psychowl'
require_relative 'support'

PROFILE_SIZE = 300
LETTER_COVERAGE = 0.999

code = ARGV[0] or abort 'usage: train_profile.rb CODE [CORPUS]'
abort "#{code}: add it to languages.tsv first" unless Psychowl::Lang[code]

code = Psychowl::Lang[code].code
corpus = ARGV[1] || File.expand_path("../corpus/#{code}.txt", __dir__)
abort "missing corpus: #{corpus}" unless File.exist?(corpus)

text = Psychowl::Text.prepare(File.read(corpus)).downcase

# trigram_positions is the engine's own ranking (most frequent first).
ranked = Psychowl::RubyEngine.send(:trigram_positions, text).sort_by { |_trigram, rank| rank }
profile = ranked.first(PROFILE_SIZE).map(&:first)
abort "#{corpus}: only #{profile.size} distinct trigrams, need #{PROFILE_SIZE}" if profile.size < PROFILE_SIZE

provenance = "Trained by tools/train_profile.rb from #{File.basename(corpus)} (#{text.length} characters)."
puts "wrote #{DataTools.write_profile(code, profile, provenance)}"

letters = text.each_char.grep_v(/[\u0000-@\[-`{-~]/).tally.sort_by { |_char, count| -count }
total = letters.sum { |_char, count| count }
covered = 0
common = letters.take_while { |_char, count| (covered += count) <= total * LETTER_COVERAGE }.map(&:first)
puts "letters covering #{(LETTER_COVERAGE * 100).round(1)}% of the corpus (for alphabets.tsv):"
puts "#{code}\t#{common.sort.join}"
