# frozen_string_literal: true

module Psychowl
  # Delegates to RubyEngine until native_speedup.rb prepends the Rust
  # extension. Same primitives either way.
  module Engine
    FILTER_ALL = 0
    FILTER_ALLOW = 1
    FILTER_DENY = 2

    class << self
      def native? = false

      def detect(text, filter_mode, filter_langs) = RubyEngine.detect(text, filter_mode, filter_langs)
      def candidates(text, filter_mode, filter_langs) = RubyEngine.candidates(text, filter_mode, filter_langs)
      def detect_many(texts, filter_mode, filter_langs) = RubyEngine.detect_many(texts, filter_mode, filter_langs)
      def segments(text, filter_mode, filter_langs) = RubyEngine.segments(text, filter_mode, filter_langs)
      def sentences(text) = RubyEngine.sentences(text)
      def detect_script(text) = RubyEngine.detect_script(text)
      def script_counts(text) = RubyEngine.script_counts(text)
    end
  end
end
