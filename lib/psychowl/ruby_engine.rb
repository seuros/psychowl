# frozen_string_literal: true

module Psychowl
  # The pure Ruby detection engine; the Rust crate implements the same
  # algorithm step by step, and test/parity_test.rb holds them to identical
  # results.
  #
  # Every method takes and returns primitives (Strings, Integers, Floats,
  # Arrays). Languages and scripts are indices into Tables. Internal calls
  # stay inside this module, never going through Engine.
  #
  # Text must already be valid UTF-8; see Psychowl::Text.
  #
  # A filter is a mode (Engine::FILTER_*) plus a list of language indices.
  module RubyEngine
    class << self
      # @return [Array(Integer, Integer, Float), nil] [language, script, confidence]
      def detect(text, filter_mode, filter_langs)
        case evaluate(text, filter_mode, filter_langs)
        in [:decided, result] then result
        in [:scored, script, [[best, best_score], [_, runner_up_score], *], trigram_count]
          [best, script, confidence(best_score, runner_up_score, trigram_count)]
        in [:nothing] then nil
        end
      end

      # Every candidate language with its score, best first.
      #
      # @return [Array<Array(Integer, Float)>] [[language, score], ...]
      def candidates(text, filter_mode, filter_langs)
        case evaluate(text, filter_mode, filter_langs)
        in [:decided, [language, _script, confidence]] then [[language, confidence]]
        in [:scored, _script, scores, _trigram_count] then scores
        in [:nothing] then []
        end
      end

      # @return [Integer, nil] the script with the most characters
      def detect_script(text) = main_script(script_counts(text))

      # @return [Array<Integer>] number of characters per script, by script index
      def script_counts(text)
        Tables::SCRIPTS.map { |script| text.count(script.charset) }
      end

      # @return [Array<Array(Integer, Integer, Float), nil>] one #detect result per text
      def detect_many(texts, filter_mode, filter_langs)
        texts.map { |text| detect(text, filter_mode, filter_langs) }
      end

      private

      # Where the text stands once its script is known (mirrors the Rust
      # `Outcome`):
      #   [:nothing]                                 no letters / no allowed language
      #   [:decided, [language, script, confidence]] one allowed language, or Han
      #   [:scored, script, scores, trigram_count]   several languages, best first
      def evaluate(text, filter_mode, filter_langs)
        counts = script_counts(text)
        script = main_script(counts)
        return [:nothing] if script.nil?

        if script == Tables::HAN
          result = detect_han(counts, filter_mode, filter_langs)
          return result ? [:decided, result] : [:nothing]
        end

        case allowed(Tables::SCRIPTS[script].languages, filter_mode, filter_langs)
        in [] then [:nothing]
        in [only] then [:decided, [only, script, 1.0]]
        in languages then [:scored, script, *language_scores(text, languages)]
        end
      end

      # Ties go to the script listed first in scripts.tsv.
      def main_script(counts)
        best = nil
        counts.each_with_index do |count, index|
          best = index if count.positive? && (best.nil? || count > counts[best])
        end
        best
      end

      def allowed(languages, filter_mode, filter_langs)
        case filter_mode
        when Engine::FILTER_ALLOW then languages.select { |language| filter_langs.include?(language) }
        when Engine::FILTER_DENY then languages.reject { |language| filter_langs.include?(language) }
        else languages
        end
      end

      # Han characters are shared by Chinese and Japanese; kana tips it to
      # Japanese.
      def detect_han(counts, filter_mode, filter_langs)
        languages = allowed(Tables::SCRIPTS[Tables::HAN].languages, filter_mode, filter_langs)
        mandarin = languages.include?(Tables::CMN)
        japanese = languages.include?(Tables::JPN)

        case [mandarin, japanese]
        in [false, false] then return nil
        in [true, false] then return [Tables::CMN, Tables::HAN, 1.0]
        in [false, true] then return [Tables::JPN, Tables::HAN, 1.0]
        in [true, true] then nil
        end

        kana = counts[Tables::HIRAGANA] + counts[Tables::KATAKANA]
        kana_ratio = kana.to_f / (counts[Tables::HAN] + kana)

        if kana_ratio > 0.2 then [Tables::JPN, Tables::HAN, 1.0]
        elsif kana_ratio > 0.05 then [Tables::JPN, Tables::HAN, 0.5]
        elsif kana_ratio > 0.02 then [Tables::CMN, Tables::HAN, 0.5]
        else [Tables::CMN, Tables::HAN, 1.0]
        end
      end

      # Blends alphabet and trigram scores. Short texts lean on the alphabet,
      # longer ones on trigrams.
      #
      # @return [Array(Array<Array(Integer, Float)>, Integer)] scores best first, trigram count
      def language_scores(text, languages)
        lowercase = text.downcase
        alphabet_scores, char_count = alphabet_scores(lowercase, languages)
        trigram_scores, trigram_count = trigram_scores(lowercase, languages)

        alphabet_weight = alphabet_weight(char_count)
        trigram_weight = 1.0 - alphabet_weight

        scores = languages.map do |language|
          score = (alphabet_scores[language] * alphabet_weight) + (trigram_scores[language] * trigram_weight)
          [language, score]
        end
        [sort_by_score(scores), trigram_count]
      end

      # 2/3 for an empty text, falling to 1/3 at 100 letters and beyond.
      def alphabet_weight(char_count) = (-(char_count / 300.0) + (2.0 / 3.0)).clamp(1.0 / 3.0, 2.0 / 3.0)

      # Highest score first; ties go to the lower language index.
      def sort_by_score(scores)
        scores.sort do |(language_a, score_a), (language_b, score_b)|
          order = score_b <=> score_a
          order.zero? ? language_a <=> language_b : order
        end
      end

      # Share of letters that belong to each language's alphabet. A letter
      # outside the alphabet counts against the language.
      def alphabet_scores(lowercase, languages)
        char_count = lowercase.length - lowercase.count(Tables::STOP_CHARS)

        unless languages.any? { |language| Tables::ALPHABETS.key?(language) }
          return [languages.to_h { |language| [language, 1.0] }, 1]
        end

        scores = languages.to_h do |language|
          letters = Tables::ALPHABETS[language]
          hits = letters ? lowercase.count(letters) : 0
          raw = (2 * hits) - char_count
          raw = 0 if raw.negative?
          [language, raw.to_f / char_count]
        end
        [scores, char_count]
      end

      # How far the best score is ahead of the runner-up, scaled by how much
      # evidence (trigrams) there was.
      def confidence(best, runner_up, count)
        return 0.0 if best.zero?
        return best if runner_up.zero?

        confident_rate = (3.0 / count) + 0.015
        rate = (best - runner_up) / runner_up
        rate > confident_rate ? 1.0 : rate / confident_rate
      end
    end
  end
end
