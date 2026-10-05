# frozen_string_literal: true

require_relative 'test_helper'

class ScriptTest < Minitest::Test
  def test_lookup
    assert_same Psychowl::Script['latin'], Psychowl::Script[:Latin]
    assert_nil Psychowl::Script[:klingon]
    assert_raises(ArgumentError) { Psychowl::Script.fetch(:klingon) }
  end

  def test_langs
    assert_equal %w[deu eng fra ita por spa], Psychowl::Script[:latin].langs.map(&:code)
    assert_equal %w[cmn jpn], Psychowl::Script[:han].langs.map(&:code)
    assert_empty Psychowl::Script[:greek].langs
  end

  def test_all_scripts_are_known
    assert_equal 25, Psychowl::Script.all.size
  end
end
