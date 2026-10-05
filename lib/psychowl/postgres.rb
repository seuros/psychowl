# frozen_string_literal: true

module Psychowl
  # PostgreSQL full-text search configurations for supported languages, for
  # to_tsvector / to_tsquery. Languages without a built-in stemmer map to
  # "simple".
  #
  #   config = Psychowl.detect(body)&.lang&.pg_regconfig || "simple"
  #   Post.where("to_tsvector(?::regconfig, body) @@ plainto_tsquery(?::regconfig, ?)", config, config, query)
  module Postgres
    REGCONFIGS = {
      'ara' => 'arabic',
      'deu' => 'german',
      'eng' => 'english',
      'fra' => 'french',
      'ind' => 'indonesian',
      'ita' => 'italian',
      'nld' => 'dutch',
      'por' => 'portuguese',
      'rus' => 'russian',
      'spa' => 'spanish',
      'tur' => 'turkish'
    }.freeze

    # @param lang [Lang, String, Symbol]
    # @return [String] a built-in PostgreSQL text search configuration
    def self.regconfig(lang) = REGCONFIGS.fetch(Lang.fetch(lang).code, 'simple')
  end

  # PostgreSQL text search configuration per language.
  class Lang
    # @return [String] PostgreSQL text search configuration, see {Postgres}
    def pg_regconfig = Postgres.regconfig(self)
  end
end
