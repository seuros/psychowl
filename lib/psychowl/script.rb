# frozen_string_literal: true

module Psychowl
  # A writing system, e.g. Latin or Cyrillic. Instances are canonical.
  #
  # @!attribute [r] name
  #   @return [String] e.g. "Cyrillic"
  # @!attribute [r] langs
  #   @return [Array<Lang>] supported languages written in this script
  Script = ::Data.define(:name, :langs) do
    # @return [String] the script name
    def to_s = name

    def inspect = "#<#{self.class} #{name}>"
  end

  # The canonical instances and lookup by name.
  class Script
    singleton_class.prepend(Lookup) # ahead of Data.define's own `[]` constructor

    ALL = Tables::SCRIPTS.map do |script|
      new(name: script.name, langs: script.languages.map { |index| Lang.at(index) }.freeze)
    end.freeze
    BY_NAME = ALL.to_h { |script| [script.name.downcase, script] }.freeze
    private_constant :ALL, :BY_NAME

    class << self
      # @return [Array<Script>] every known script (frozen)
      def all = ALL

      private :new

      private

      def by_key = BY_NAME
      def unknown_key_message = 'unknown script'
    end
  end
end
