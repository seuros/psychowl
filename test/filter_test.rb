# frozen_string_literal: true

require_relative 'test_helper'

class FilterTest < Minitest::Test
  PORTUGUESE = 'Eu gostaria de reservar uma mesa para duas pessoas amanhã à noite, por favor.'

  def test_allowlist_restricts_candidates
    assert_equal 'spa', Psychowl.detect_lang(PORTUGUESE, allowlist: %w[spa eng]).code
  end

  def test_denylist_excludes_languages
    assert_equal 'spa', Psychowl.detect_lang(PORTUGUESE, denylist: [:por]).code
  end

  def test_lists_accept_lang_objects_and_iso639_1_codes
    assert_equal 'spa', Psychowl.detect_lang(PORTUGUESE, allowlist: [Psychowl::Lang[:spa], :en]).code
  end

  def test_single_allowed_language_is_certain
    info = Psychowl.detect(PORTUGUESE, allowlist: [:eng])

    assert_equal 'eng', info.lang.code
    assert_in_delta 1.0, info.confidence
  end

  def test_filter_applies_to_single_language_scripts
    assert_nil Psychowl.detect('Летом мы ездили на море', allowlist: %i[en fr])
    assert_nil Psychowl.detect('مرحبا بالعالم', denylist: [:ara])
  end

  def test_filter_applies_to_han
    japanese = '日本語を勉強するのは難しいですが、とても楽しいです。'

    assert_equal 'cmn', Psychowl.detect_lang('学习一门新的语言', allowlist: [:cmn]).code
    assert_equal 'jpn', Psychowl.detect_lang('学习一门新的语言', allowlist: [:jpn]).code
    assert_nil Psychowl.detect('学习一门新的语言', denylist: %i[cmn jpn])
    assert_equal 'jpn', Psychowl.detect_lang(japanese, denylist: [:cmn]).code
  end

  def test_invalid_filters
    assert_raises(ArgumentError) { Psychowl.detect('x', allowlist: [:eng], denylist: [:fra]) }
    assert_raises(ArgumentError) { Psychowl.detect('x', allowlist: []) }
    assert_raises(ArgumentError) { Psychowl.detect('x', allowlist: ['klingon']) }
  end

  def test_empty_denylist_means_no_filter
    assert_equal 'por', Psychowl.detect_lang(PORTUGUESE, denylist: []).code
  end

  def test_detector_is_frozen_and_reusable
    detector = Psychowl::Detector.new(allowlist: %i[en de])

    assert_predicate detector, :frozen?
    assert_equal [Psychowl::Lang[:eng], Psychowl::Lang[:deu]], detector.allowlist
    assert_equal 'deu', detector.detect_lang('Das ist ein sehr guter Satz auf Deutsch.').code
    assert_equal '#<Psychowl::Detector allowlist=["eng", "deu"]>', detector.inspect
  end
end
