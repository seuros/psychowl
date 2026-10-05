# frozen_string_literal: true

# Optional Rust speedup. When the native extension is available, its
# functions replace the pure Ruby engine one-for-one; otherwise the Ruby
# engine stays. Set DISABLE_PSYCHOWL_NATIVE (or DISABLE_MATRYOSHKA_NATIVE for
# every Matryoshka gem) to a non-empty value to force pure Ruby; an empty
# value, as CI matrices often produce, leaves the extension on.
return if %w[DISABLE_PSYCHOWL_NATIVE DISABLE_MATRYOSHKA_NATIVE].any? { |name| !ENV.fetch(name, '').empty? }

begin
  begin
    require_relative "#{RUBY_VERSION[/\A\d+\.\d+/]}/psychowl_native"
  rescue LoadError
    require 'psychowl/psychowl_native'
  end
rescue LoadError
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
