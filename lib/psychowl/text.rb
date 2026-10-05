# frozen_string_literal: true

module Psychowl
  # Input validation shared by both engines: they only ever see valid UTF-8.
  module Text
    class << self
      # @param text [String, #to_str]
      # @return [String] valid UTF-8
      # @raise [TypeError] not a String
      # @raise [EncodingError] invalid bytes, or not convertible to UTF-8
      def prepare(text)
        string = String.try_convert(text)
        raise TypeError, "no implicit conversion of #{text.nil? ? 'nil' : text.class} into String" unless string

        utf8 =
          case string.encoding
          when Encoding::UTF_8, Encoding::US_ASCII, Encoding::BINARY then string.dup.force_encoding(Encoding::UTF_8)
          else string.encode(Encoding::UTF_8)
          end
        raise EncodingError, 'text is not valid UTF-8' unless utf8.valid_encoding?

        utf8
      end
    end
  end
end
