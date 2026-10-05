# frozen_string_literal: true

require_relative 'test_helper'

class DetectionTest < Minitest::Test
  def test_every_sample_is_detected_as_its_language
    Samples.all.each do |code, samples|
      samples.each_with_index do |sample, index|
        assert_equal code, Psychowl.detect_lang(sample)&.code, "#{code} sample #{index}: #{sample[0, 60]}"
      end
    end
  end

  def test_every_supported_language_has_samples
    assert_equal Psychowl::Lang.all.map(&:code).sort, Samples.all.keys.sort
  end

  def test_detect_returns_info
    info = Psychowl.detect('Летом мы ездили на море и каждый день ' \
                           'купались и загорали на пляже.')

    assert_equal Psychowl::Lang[:rus], info.lang
    assert_equal Psychowl::Script[:cyrillic], info.script
    assert_in_delta 1.0, info.confidence
    assert_predicate info, :reliable?
  end

  def test_info_supports_pattern_matching
    matched =
      case Psychowl.detect('Scientists have discovered a new species of frog in the rainforest.')
      in { lang: { code: 'eng' }, script: { name: 'Latin' } } then true
      else false
      end

    assert matched
  end

  def test_japanese_with_mostly_han_characters
    text = 'この間、川越城や松井田城などの諸城を拡張・改修 ' \
           '河越城の三の丸と八幡郭など拡張、松井田城の大道寺郭構築など'

    assert_equal 'jpn', Psychowl.detect_lang(text).code
  end

  def test_pure_han_is_mandarin
    assert_equal 'cmn', Psychowl.detect_lang('学习一门新的语言需要很多时间和耐心').code
  end

  def test_nothing_to_detect
    ['', '   ', '1234 5678', '!!! ??? ...', '😀🎉'].each do |text|
      assert_nil Psychowl.detect(text), text.inspect
    end
  end

  def test_unsupported_script_detects_script_but_no_language
    text = 'Μετά τη διάλυση της Δεύτερης Τριανδρίας'

    assert_nil Psychowl.detect(text)
    assert_equal 'Greek', Psychowl.detect_script(text).name
  end

  def test_detect_script
    assert_equal 'Cyrillic', Psychowl.detect_script('Благодаря Эсперанто').name
    assert_equal 'Hiragana', Psychowl.detect_script('こんにちは').name
    assert_equal 'Arabic', Psychowl.detect_script('مرحبا بالعالم').name
    assert_nil Psychowl.detect_script('')
  end

  def test_script_ties_go_to_the_higher_priority_script
    assert_equal 'Latin', Psychowl.detect_script('ab вы').name
  end
end
