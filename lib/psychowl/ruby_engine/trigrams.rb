# frozen_string_literal: true

module Psychowl
  # The trigram model: rank a text's character trigrams and measure how far
  # that ranking is from each language profile. Mirrors trigram.rs in the
  # Rust crate.
  module RubyEngine
    # A profile trigram missing from the text costs this much distance.
    MAX_TRIGRAM_DISTANCE = 300
    MAX_TOTAL_DISTANCE = MAX_TRIGRAM_DISTANCE * MAX_TRIGRAM_DISTANCE
    # Only the most frequent trigrams of the text are compared.
    TEXT_TRIGRAMS_SIZE = 600

    class << self
      private

      # Similarity between the text's trigram ranking and each profile.
      def trigram_scores(lowercase, languages)
        positions = trigram_positions(lowercase)
        max_distance = positions.size * MAX_TRIGRAM_DISTANCE

        scores = languages.to_h do |language|
          profile = Tables::TRIGRAMS[language]
          if profile
            distance = trigram_distance(profile, positions)
            [language, (max_distance - distance).to_f / max_distance]
          else
            [language, 0.0]
          end
        end
        [scores, positions.size]
      end

      # {trigram => rank}: the text's most frequent trigrams, most frequent
      # first (ties broken by the trigram itself, descending).
      def trigram_positions(lowercase)
        ranked = count_trigrams(lowercase).sort do |(trigram_a, count_a), (trigram_b, count_b)|
          [count_b, trigram_b] <=> [count_a, trigram_a]
        end
        ranked.first(TEXT_TRIGRAMS_SIZE).each_with_index.to_h { |(trigram, _count), rank| [trigram, rank] }
      end

      # {trigram => occurrences}. Punctuation and digits act as spaces;
      # trigrams that are only word boundary are skipped.
      def count_trigrams(lowercase)
        counts = Hash.new(0)
        first = ' '
        second = nil

        "#{lowercase.tr(Tables::STOP_CHARS, ' ')} ".each_char do |third|
          if second.nil?
            second = third
            next
          end

          counts["#{first}#{second}#{third}"] += 1 unless second == ' ' && (first == ' ' || third == ' ')
          first = second
          second = third
        end
        counts
      end

      def trigram_distance(profile, positions)
        total = 0
        profile.each_with_index do |trigram, index|
          position = positions[trigram]
          total += position ? (position - index).abs : MAX_TRIGRAM_DISTANCE
        end

        unique = positions.size
        total -= (MAX_TRIGRAM_DISTANCE - unique) * MAX_TRIGRAM_DISTANCE if unique < MAX_TRIGRAM_DISTANCE
        total.clamp(0, MAX_TOTAL_DISTANCE)
      end
    end
  end
end
