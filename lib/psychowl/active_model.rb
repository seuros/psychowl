# frozen_string_literal: true

require 'active_model'
require 'psychowl'

I18n.load_path << File.expand_path('locale/en.yml', __dir__)

module ActiveModel
  module Validations
    # Validates the language an attribute is written in.
    #
    #   validates :body, language: { in: %i[en fr] }
    #   validates :title, language: { not_in: :ru, reliable: true }, allow_blank: true
    #   validates :bio, language: { in: :en, minimum_confidence: 0.5 }
    #
    # Options:
    # * +in+ / +not_in+ - languages (codes or Psychowl::Lang) to accept / reject
    # * +reliable+ - require a reliable detection
    # * +minimum_confidence+ - require at least this confidence (0.0 to 1.0)
    #
    # Errors: +:language_undetected+, +:language_not_allowed+,
    # +:language_uncertain+, each with a +%{language}+ interpolation.
    class LanguageValidator < EachValidator
      def check_validity!
        raise ArgumentError, 'pass either :in or :not_in, not both' if options[:in] && options[:not_in]

        @allowed = resolve(options[:in])
        @denied = resolve(options[:not_in])
        minimum = options[:minimum_confidence]
        return if minimum.nil? || (minimum.is_a?(Numeric) && minimum.between?(0, 1))

        raise ArgumentError, ':minimum_confidence must be between 0 and 1'
      end

      def validate_each(record, attribute, value)
        info = Psychowl.detect(value.to_s)
        return add_error(record, attribute, :language_undetected, nil) if info.nil?

        lang = info.lang
        return add_error(record, attribute, :language_not_allowed, lang) if @allowed && !@allowed.include?(lang)
        return add_error(record, attribute, :language_not_allowed, lang) if @denied&.include?(lang)

        add_error(record, attribute, :language_uncertain, lang) if uncertain?(info)
      end

      private

      def uncertain?(info)
        return true if options[:reliable] && !info.reliable?

        minimum = options[:minimum_confidence]
        !minimum.nil? && info.confidence < minimum
      end

      def resolve(list) = list && Array(list).map { |code| Psychowl::Lang.fetch(code) }

      def add_error(record, attribute, type, lang)
        details = { language: lang&.eng_name }
        details[:message] = options[:message] if options[:message]
        record.errors.add(attribute, type, **details)
      end
    end
  end
end
