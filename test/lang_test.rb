# frozen_string_literal: true

require_relative 'test_helper'

class LangTest < Minitest::Test
  def test_lookup_by_iso639_3_and_iso639_1
    german = Psychowl::Lang[:deu]

    assert_same german, Psychowl::Lang['de']
    assert_same german, Psychowl::Lang['DEU']
    assert_same german, Psychowl::Lang[german]
    assert_nil Psychowl::Lang[:klingon]
    assert_raises(ArgumentError) { Psychowl::Lang.fetch(:klingon) }
  end

  def test_attributes
    german = Psychowl::Lang[:deu]

    assert_equal %w[deu de Deutsch German], [german.code, german.iso639_1, german.name, german.eng_name]
    assert_equal :de, german.locale
    assert_equal 'deu', german.to_s
    assert_equal '#<Psychowl::Lang deu (German)>', german.inspect
  end

  def test_all_is_frozen_and_canonical
    assert_predicate Psychowl::Lang.all, :frozen?
    assert_same Psychowl::Lang.all.first, Psychowl::Lang[Psychowl::Lang.all.first.code]
    assert_same Psychowl.detect_lang('Das ist ein sehr guter Satz auf Deutsch.'), Psychowl::Lang[:deu]
  end

  def test_cannot_be_instantiated
    assert_raises(NoMethodError) { Psychowl::Lang.new(code: 'x', iso639_1: 'x', name: 'x', eng_name: 'x') }
  end
end
