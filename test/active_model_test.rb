# frozen_string_literal: true

require_relative 'test_helper'
require 'psychowl/active_model'

class ActiveModelTest < Minitest::Test
  ENGLISH = 'Scientists have discovered a new species of frog living deep in the rainforest.'
  FRENCH = 'Nous sommes allés à la plage pendant les vacances et il a fait très beau.'

  def model(**language_options)
    Class.new do
      include ActiveModel::Validations

      attr_accessor :body

      def self.name = 'Post'

      validates :body, language: language_options, allow_blank: true
    end
  end

  def errors_for(klass, body)
    record = klass.new
    record.body = body
    record.validate
    record.errors
  end

  def test_in
    klass = model(in: %i[en de])

    assert_empty errors_for(klass, ENGLISH)
    assert_equal ['is written in French, which is not allowed'], errors_for(klass, FRENCH)[:body]
    assert_equal [{ error: :language_not_allowed, language: 'French' }], errors_for(klass, FRENCH).details[:body]
  end

  def test_not_in
    klass = model(not_in: :fra)

    assert_empty errors_for(klass, ENGLISH)
    refute_empty errors_for(klass, FRENCH)
  end

  def test_undetected
    assert_equal ['is not written in a recognizable language'], errors_for(model(in: :en), '12345 !!!')[:body]
  end

  def test_reliability
    klass = model(in: :en, reliable: true)

    assert_empty errors_for(klass, ENGLISH)
    errors = errors_for(klass, 'Good morning').details[:body].map { it[:error] }

    assert_equal [:language_uncertain], errors
  end

  def test_minimum_confidence
    assert_empty errors_for(model(minimum_confidence: 0.9), ENGLISH)
  end

  def test_custom_message
    assert_equal ['wrong language'], errors_for(model(in: :de, message: 'wrong language'), ENGLISH)[:body]
  end

  def test_allow_blank
    assert_empty errors_for(model(in: :en), '')
  end

  def test_invalid_options
    assert_raises(ArgumentError) { model(in: :en, not_in: :fr) }
    assert_raises(ArgumentError) { model(in: :klingon) }
    assert_raises(ArgumentError) { model(minimum_confidence: 2) }
  end

  def test_postgres_regconfig
    assert_equal 'english', Psychowl::Lang[:en].pg_regconfig
    assert_equal 'simple', Psychowl::Lang[:ja].pg_regconfig
    assert_equal 'german', Psychowl::Postgres.regconfig(:deu)
  end
end
