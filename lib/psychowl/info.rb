# frozen_string_literal: true

module Psychowl
  # Outcome of a detection. Supports pattern matching:
  #
  #   case Psychowl.detect(text)
  #   in {lang: {code: "eng"}, reliable: true} then ...
  #   end
  #
  # @!attribute [r] lang
  #   @return [Lang]
  # @!attribute [r] script
  #   @return [Script]
  # @!attribute [r] confidence
  #   @return [Float] 0.0 to 1.0
  # @!attribute [r] reliable
  #   @return [Boolean] confidence above {RELIABLE_CONFIDENCE}
  Info = ::Data.define(:lang, :script, :confidence, :reliable) do
    # @return [Boolean]
    def reliable? = reliable

    def inspect
      "#<#{self.class} lang=#{lang.code} script=#{script.name} " \
        "confidence=#{confidence.round(4)} reliable=#{reliable}>"
    end
  end

  # Reliability threshold and construction from engine results.
  class Info
    RELIABLE_CONFIDENCE = 0.9

    # @api private
    def self.from_engine((lang, script, confidence))
      new(lang: Lang.at(lang), script: Script.at(script), confidence:,
          reliable: confidence > RELIABLE_CONFIDENCE)
    end
  end
end
