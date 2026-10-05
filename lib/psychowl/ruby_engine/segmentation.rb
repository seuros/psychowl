# frozen_string_literal: true

module Psychowl
  # Per-sentence detection for mixed-language text; mirrors segment.rs in
  # the Rust crate.
  module RubyEngine
    # Sentence-ending marks that need a following space ("3.14" is no boundary).
    SENTENCE_MARKS = %W[. ! ? \u2026].freeze
    # CJK sentence-ending marks, no space needed.
    CLOSING_MARKS = %W[\u3002 \uFF01 \uFF1F].freeze

    class << self
      # Splits the text into sentences, detects each one, and merges runs of
      # sentences in the same language. Sentences without a detectable
      # language (numbers, emoji, unsupported scripts) join the segment
      # before them, or the first segment when they lead the text. Each
      # merged segment is detected again as a whole; if that lands on another
      # language, the segment keeps the result of its first sentence.
      #
      # @return [Array<Array(Integer, Integer, Integer, Integer, Float)>]
      #   [[start, end, language, script, confidence], ...] with character
      #   offsets, end exclusive
      def segments(text, filter_mode, filter_langs)
        runs = [] # [start, end, first sentence's detection]
        leading_start = nil

        sentences(text).each do |start, finish|
          result = detect(text[start...finish], filter_mode, filter_langs)

          if result.nil?
            if runs.empty?
              leading_start ||= start
            else
              runs.last[1] = finish
            end
          elsif runs.any? && runs.last[2][0] == result[0]
            runs.last[1] = finish
          else
            runs << [leading_start || start, finish, result]
            leading_start = nil
          end
        end

        runs.map do |start, finish, first|
          whole = detect(text[start...finish], filter_mode, filter_langs)
          whole && whole[0] == first[0] ? [start, finish, *whole] : [start, finish, *first]
        end
      end

      # Sentence boundaries as [start, end] character offsets. A sentence
      # ends after a newline, after 。！？, or after a run of . ! ? …
      # followed by a space; trailing spaces stay with the sentence.
      def sentences(text)
        chars = text.chars
        sentences = []
        start = 0
        index = 0

        while index < chars.size
          char = chars[index]
          boundary = false

          if char == "\n" || CLOSING_MARKS.include?(char)
            index += 1
            boundary = true
          elsif SENTENCE_MARKS.include?(char)
            index += 1 while index < chars.size && SENTENCE_MARKS.include?(chars[index])
            boundary = index == chars.size || space?(chars[index])
          else
            index += 1
          end
          next unless boundary

          index += 1 while index < chars.size && space?(chars[index])
          sentences << [start, index]
          start = index
        end

        sentences << [start, chars.size] if start < chars.size
        sentences
      end

      private

      # ASCII whitespace and controls, no-break space, ideographic space.
      def space?(char) = char <= ' ' || char == "\u00A0" || char == "\u3000"
    end
  end
end
