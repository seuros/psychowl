# frozen_string_literal: true

require_relative 'psychowl/version'
require_relative 'psychowl/data_file'
require_relative 'psychowl/tables'
require_relative 'psychowl/text'
require_relative 'psychowl/engine'
require_relative 'psychowl/ruby_engine'
require_relative 'psychowl/ruby_engine/segmentation'
require_relative 'psychowl/ruby_engine/trigrams'
require_relative 'psychowl/lookup'
require_relative 'psychowl/lang'
require_relative 'psychowl/script'
require_relative 'psychowl/info'
require_relative 'psychowl/segment'
require_relative 'psychowl/detector'

# Natural language and script detection. It knows what language you speak.
# It knows you skipped your lesson.
#
#   info = Psychowl.detect("Die Deutsche Bahn ist heute pünktlich. Wir ermitteln.")
#   info.lang.code   # => "deu"
#   info.script.name # => "Latin"
module Psychowl
  DEFAULT_DETECTOR = Detector.new
  private_constant :DEFAULT_DETECTOR

  class << self
    # @param text [String]
    # @param allowlist [Array<Lang, String, Symbol>, nil] only consider these
    # @param denylist [Array<Lang, String, Symbol>, nil] never consider these
    # @return [Info, nil] nil when no supported language was found
    # @raise [TypeError] text is not a String
    # @raise [EncodingError] text is not valid UTF-8 (or convertible to it)
    # @raise [ArgumentError] invalid allowlist/denylist, see {Detector#initialize}
    def detect(text, allowlist: nil, denylist: nil) = detector(allowlist, denylist).detect(text)

    # @param (see .detect)
    # @return [Lang, nil]
    def detect_lang(text, allowlist: nil, denylist: nil) = detector(allowlist, denylist).detect_lang(text)

    # @param text [String]
    # @return [Script, nil]
    def detect_script(text) = DEFAULT_DETECTOR.detect_script(text)

    # @param (see .detect)
    # @param limit [Integer, nil]
    # @return [Array<Array(Lang, Float)>] see {Detector#candidates}
    def candidates(text, limit: nil, allowlist: nil, denylist: nil)
      detector(allowlist, denylist).candidates(text, limit:)
    end

    # @param texts [Array<String>]
    # @param allowlist [Array<Lang, String, Symbol>, nil]
    # @param denylist [Array<Lang, String, Symbol>, nil]
    # @return [Array<Info, nil>] see {Detector#detect_many}
    def detect_many(texts, allowlist: nil, denylist: nil) = detector(allowlist, denylist).detect_many(texts)

    # @param (see .detect)
    # @return [Array<Segment>] see {Detector#segments}
    def segments(text, allowlist: nil, denylist: nil) = detector(allowlist, denylist).segments(text)

    # @param text [String]
    # @return [Hash{Script => Float}] see {Detector#scripts}
    def scripts(text) = DEFAULT_DETECTOR.scripts(text)

    # @return [Symbol] :native when the Rust extension is loaded, :ruby otherwise
    def backend = Engine.native? ? :native : :ruby

    private

    def detector(allowlist, denylist)
      return DEFAULT_DETECTOR if allowlist.nil? && denylist.nil?

      Detector.new(allowlist:, denylist:)
    end
  end
end

require_relative 'psychowl/postgres'
require_relative 'psychowl/native_speedup'
require_relative 'psychowl/railtie' if defined?(Rails::Railtie)
