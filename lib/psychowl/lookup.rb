# frozen_string_literal: true

module Psychowl
  # Case-insensitive lookup for Lang and Script. Prepended, because Data
  # defines its own `[]`; expects `all`, `by_key` and `unknown_key_message`.
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
