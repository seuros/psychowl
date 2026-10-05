# frozen_string_literal: true

require_relative 'test_helper'

class FeaturesTest < Minitest::Test
  MIXED = 'Hello, this is an English sentence about cats. Ceci est une phrase en français sur les chats. ' \
          '12345. Und das ist ein deutscher Satz über Katzen.'

  def test_segments_split_mixed_text
    segments = Psychowl.segments(MIXED)

    assert_equal(%w[eng fra deu], segments.map { it.lang.code })
    assert_equal 'Ceci est une phrase en français sur les chats. 12345. ', segments[1].text
    assert_equal MIXED, segments.map(&:text).join
    segments.each { |segment| assert_equal segment.text, MIXED[segment.range] }
  end

  def test_segments_of_text_without_language
    assert_empty Psychowl.segments('123. 456.')
    assert_empty Psychowl.segments('')
  end

  def test_segments_use_character_offsets
    text = '日本語を勉強するのは難しいですが、とても楽しいです。' \
           'This sentence is written in plain English.'
    segments = Psychowl.segments(text)

    assert_equal(%w[jpn eng], segments.map { it.lang.code })
    assert_equal 0...26, segments.first.range
  end

  def test_detect_many_keeps_order_and_nils
    texts = ['Das ist ein sehr guter Satz auf Deutsch.', '1234', 'Летом мы ездили на море']

    assert_equal(['deu', nil, 'rus'], Psychowl.detect_many(texts).map { it&.lang&.code })
    assert_equal(['ita', nil, nil], Psychowl.detect_many(texts, allowlist: [:ita]).map { it&.lang&.code })
  end

  def test_detect_many_validates_every_text
    assert_raises(TypeError) { Psychowl.detect_many(['ok', nil]) }
  end

  def test_scripts_breakdown
    shares = Psychowl.scripts('Hello мир')

    assert_equal %w[Latin Cyrillic], shares.keys.map(&:name)
    assert_in_delta 5.0 / 8, shares[Psychowl::Script[:latin]]
    assert_in_delta 1.0, shares.values.sum
    assert_empty Psychowl.scripts('123 !!!')
  end
end
