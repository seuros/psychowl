# frozen_string_literal: true

module Psychowl
  # A stretch of text in one language, from {Psychowl.segments}.
  #
  # @!attribute [r] text
  #   @return [String] the segment's text
  # @!attribute [r] range
  #   @return [Range] character offsets in the original text
  # @!attribute [r] info
  #   @return [Info] the detection for this segment
  Segment = ::Data.define(:text, :range, :info) do
    # @return [Lang]
    def lang = info.lang

    # @return [Script]
    def script = info.script

    # @return [Float]
    def confidence = info.confidence

    def inspect = "#<#{self.class} #{range} #{info.lang.code} #{text[0, 30].inspect}>"
  end
end
