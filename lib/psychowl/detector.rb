# frozen_string_literal: true

module Psychowl
  # A reusable, frozen detector, optionally limited by an allowlist or denylist.
  #
  #   detector = Psychowl::Detector.new(allowlist: %i[en fr de])
  #   detector.detect_lang("Traversez la rue, je vous trouverai un travail.")
  #   # => #<Psychowl::Lang fra (French)>
  class Detector
    # @return [Array<Lang>, nil]
    attr_reader :allowlist

    # @return [Array<Lang>, nil]
    attr_reader :denylist

    # @param allowlist [Array<Lang, String, Symbol>, nil] only consider these
    # @param denylist [Array<Lang, String, Symbol>, nil] never consider these
    # @raise [ArgumentError] both lists given, an empty allowlist, or an
    #   unsupported language code
    def initialize(allowlist: nil, denylist: nil)
      raise ArgumentError, 'pass either allowlist: or denylist:, not both' unless allowlist.nil? || denylist.nil?

      @allowlist = allowlist && resolve(allowlist)
      @denylist = denylist && resolve(denylist)
      raise ArgumentError, 'allowlist must not be empty' if @allowlist && @allowlist.empty?

      @filter_mode, @filter_langs = engine_filter
      freeze
    end

    # @param text [String]
    # @return [Info, nil] nil when no supported language was found
    # @raise [TypeError] text is not a String
    # @raise [EncodingError] text is not valid UTF-8 (or convertible to it)
    def detect(text)
      result = Engine.detect(Text.prepare(text), @filter_mode, @filter_langs)
      result && Info.from_engine(result)
    end

    # @param (see #detect)
    # @return [Lang, nil]
    def detect_lang(text) = detect(text)&.lang

    # Scripts ignore the language filter.
    #
    # @param (see #detect)
    # @return [Script, nil]
    def detect_script(text)
      index = Engine.detect_script(Text.prepare(text))
      index && Script.at(index)
    end

    # Every candidate language of the text's script with its score, best
    # first. Scores are relative to each other, not probabilities.
    #
    # @param (see #detect)
    # @param limit [Integer, nil] keep only the first +limit+ candidates
    # @return [Array<Array(Lang, Float)>]
    def candidates(text, limit: nil)
      ranked = Engine.candidates(Text.prepare(text), @filter_mode, @filter_langs)
      ranked = ranked.first(limit) if limit
      ranked.map { |lang, score| [Lang.at(lang), score] }
    end

    # On all CPU cores with the native engine.
    #
    # @param texts [Array<String>]
    # @return [Array<Info, nil>] one result per text, in order
    def detect_many(texts)
      prepared = texts.map { |text| Text.prepare(text) }
      Engine.detect_many(prepared, @filter_mode, @filter_langs).map { |result| result && Info.from_engine(result) }
    end

    # Runs of same-language sentences, for mixed-language text.
    #
    # @param (see #detect)
    # @return [Array<Segment>]
    def segments(text)
      text = Text.prepare(text)
      Engine.segments(text, @filter_mode, @filter_langs).map do |start, finish, *result|
        Segment.new(text: text[start...finish], range: start...finish, info: Info.from_engine(result))
      end
    end

    # Share of each writing system among the text's letters, largest first.
    # Ignores the language filter.
    #
    # @param (see #detect)
    # @return [Hash{Script => Float}] shares summing to 1.0; empty without letters
    def scripts(text)
      counts = Engine.script_counts(Text.prepare(text))
      total = counts.sum
      return {} if total.zero?

      shares = counts.each_with_index.filter_map do |count, index|
        [Script.at(index), count.fdiv(total)] if count.positive?
      end
      shares.sort_by { |_script, share| -share }.to_h
    end

    def inspect
      filter =
        if allowlist then " allowlist=#{allowlist.map(&:code)}"
        elsif denylist then " denylist=#{denylist.map(&:code)}"
        end
      "#<#{self.class}#{filter}>"
    end

    private

    # [mode, language indices] as the engines take them
    def engine_filter
      if allowlist then [Engine::FILTER_ALLOW, indices(allowlist)]
      elsif denylist then [Engine::FILTER_DENY, indices(denylist)]
      else [Engine::FILTER_ALL, [].freeze]
      end
    end

    def indices(langs) = langs.map { |lang| Lang.index(lang) }.freeze

    def resolve(list) = Array(list).map { |code| Lang.fetch(code) }.uniq.freeze
  end
end
