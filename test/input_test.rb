# frozen_string_literal: true

require_relative 'test_helper'

class InputTest < Minitest::Test
  RUSSIAN = 'Привет, как у тебя дела? Всё хорошо?'

  def test_rejects_non_strings
    [nil, 42, :symbol, ['array']].each do |value|
      assert_raises(TypeError) { Psychowl.detect(value) }
    end
  end

  def test_accepts_implicit_strings
    text = Object.new
    def text.to_str = 'Das ist ein sehr guter Satz auf Deutsch.'

    assert_equal 'deu', Psychowl.detect_lang(text).code
  end

  def test_transcodes_other_encodings
    assert_equal 'rus', Psychowl.detect_lang(RUSSIAN.encode('Windows-1251')).code
  end

  def test_accepts_binary_strings_holding_utf8
    assert_equal 'rus', Psychowl.detect_lang(RUSSIAN.b).code
  end

  def test_rejects_invalid_utf8
    assert_raises(EncodingError) { Psychowl.detect("caf\xE9".b) }
    assert_raises(EncodingError) { Psychowl.detect((+"caf\xE9").force_encoding(Encoding::UTF_8)) }
  end

  def test_does_not_modify_input
    text = (+'Das ist ein sehr guter Satz auf Deutsch.').force_encoding(Encoding::BINARY)
    Psychowl.detect(text)

    assert_equal Encoding::BINARY, text.encoding
  end
end
