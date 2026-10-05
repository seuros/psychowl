# frozen_string_literal: true

# A non-empty DISABLE_PSYCHOWL_NATIVE or DISABLE_MATRYOSHKA_NATIVE forces pure
# Ruby; an empty one (as CI matrices set) does not.
return if %w[DISABLE_PSYCHOWL_NATIVE DISABLE_MATRYOSHKA_NATIVE].any? { !ENV.fetch(it, '').empty? }

begin
  begin
    require_relative "#{RUBY_VERSION[/\A\d+\.\d+/]}/psychowl_native"
  rescue LoadError
    require 'psychowl/psychowl_native'
  end
rescue LoadError
  return
end

# An extension built from other data files would map indices to the wrong
# languages: keep the Ruby engine instead.
expected = [Psychowl::Tables::LANGUAGES.map(&:first), Psychowl::Tables::SCRIPTS.map(&:name)]
unless PsychowlNative.tables == expected
  warn "psychowl: native extension was built from different language data (rebuild it); using the pure Ruby engine"
  return
end

# Swaps the Rust extension in behind Engine.
module Psychowl
  # Routes every Engine method to the Rust extension (PsychowlNative).
  module NativeSpeedup
    def native? = true
    def detect(text, filter_mode, filter_langs) = PsychowlNative.detect(text, filter_mode, filter_langs)
    def candidates(text, filter_mode, filter_langs) = PsychowlNative.candidates(text, filter_mode, filter_langs)
    def detect_script(text) = PsychowlNative.detect_script(text)
    def script_counts(text) = PsychowlNative.script_counts(text)
    def detect_many(texts, filter_mode, filter_langs) = PsychowlNative.detect_many(texts, filter_mode, filter_langs)
    def segments(text, filter_mode, filter_langs) = PsychowlNative.segments(text, filter_mode, filter_langs)
    def sentences(text) = PsychowlNative.sentences(text)
  end

  Engine.singleton_class.prepend(NativeSpeedup)
end
