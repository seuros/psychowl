# frozen_string_literal: true

module Psychowl
  # A supported language. Instances are canonical: every API hands out the
  # same frozen object for a given language.
  #
  #   Psychowl::Lang[:de]      # ISO 639-1
  #   Psychowl::Lang["deu"]    # ISO 639-3
  #   Psychowl::Lang.fetch(:x) # raises ArgumentError
  #
  # @!attribute [r] code
  #   @return [String] ISO 639-3 code, e.g. "deu"
  # @!attribute [r] iso639_1
  #   @return [String] ISO 639-1 code, e.g. "de"
  # @!attribute [r] name
  #   @return [String] name in the language itself, e.g. "Deutsch"
  # @!attribute [r] eng_name
  #   @return [String] English name, e.g. "German"
  Lang = ::Data.define(:code, :iso639_1, :name, :eng_name) do
    # @return [Symbol] the ISO 639-1 code as an I18n-style locale, e.g. :de
    def locale = iso639_1.to_sym

    # @return [String] the ISO 639-3 code
    def to_s = code

    def inspect = "#<#{self.class} #{code} (#{eng_name})>"
  end

  # The canonical instances and lookup by code.
  class Lang
    singleton_class.prepend(Lookup) # ahead of Data.define's own `[]` constructor

    ALL = Tables::LANGUAGES.map do |code, iso639_1, eng_name, name|
      new(code:, iso639_1:, name:, eng_name:)
    end.freeze
    BY_CODE = ALL.flat_map { |lang| [[lang.code, lang], [lang.iso639_1, lang]] }.to_h.freeze
    INDEX = ALL.each_with_index.to_h.compare_by_identity.freeze
    private_constant :ALL, :BY_CODE, :INDEX

    class << self
      # @return [Array<Lang>] every supported language (frozen)
      def all = ALL

      # @api private
      def index(lang) = INDEX.fetch(lang)

      private :new

      private

      def by_key = BY_CODE
      def unknown_key_message = 'unsupported language'
    end
  end
end
