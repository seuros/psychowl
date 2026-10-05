# frozen_string_literal: true

module Psychowl
  # Class-level lookup shared by Lang and Script: canonical frozen instances
  # found by a case-insensitive key. Prepended to the singleton class (Data
  # classes define their own `[]`); the class defines `all`,
  # a private `by_key` table and a private `unknown_key_message`.
  module Lookup
    # @param key [self, String, Symbol]
    # @return [self, nil]
    def [](key)
      return key if key.is_a?(self)

      by_key[key.to_s.downcase]
    end

    # @param (see #[])
    # @return [self]
    # @raise [ArgumentError] unknown key
    def fetch(key)
      self[key] or raise ArgumentError, "#{unknown_key_message}: #{key.inspect}"
    end

    # @api private
    def at(index) = all.fetch(index)
  end
end
