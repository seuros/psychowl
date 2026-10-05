# frozen_string_literal: true

require_relative 'test_helper'

# The Rust engine must give exactly the same answers as the Ruby engine,
# confidence floats included.
class ParityTest < Minitest::Test
  def self.indices(*codes) = codes.map { Psychowl::Lang.index(Psychowl::Lang.fetch(it)) }

  FILTERS = [
    [Psychowl::Engine::FILTER_ALL, []],
    [Psychowl::Engine::FILTER_ALLOW, indices('spa', 'por', 'ita')],
    [Psychowl::Engine::FILTER_DENY, indices('eng', 'cmn')]
  ].freeze

  EXTRA = [
    '', ' ', '123 456', '😀', 'a', 'ab вы', 'ΣΟΦΟΣ σοφός philosophy',
    'Can you tell me where is Schönheitstraße?', 'Façade', "İstanbul'da güzel bir gün",
    '東京スカイツリーは高い', '漢字かな交じり文', 'مرحبا Hello Привет',
    'The meeting is at 3pm, ok? Merci beaucoup! ¡Gracias!',
    'ᴫᵸ ᴬ',
    'Hello there my friend. Μετά τη διάλυση της Δεύτερης Τριανδρίας. ' \
    'Bonjour mes amis, comment allez-vous?',
    '日本語を勉強するのは難しいですが、とても楽しいです。' \
    'This sentence is written in plain English. 学习一门新的语言需要很多时间。',
    "First line\nSecond line!\n\n¿Qué tal? Muy bien… gracias"
  ].freeze

  def setup
    skip 'native extension not loaded' unless Psychowl.backend == :native
  end

  def test_detect_matches
    each_input do |text|
      FILTERS.each do |mode, langs|
        assert_parity ruby(:detect, text, mode, langs), PsychowlNative.detect(text, mode, langs), text
      end
    end
  end

  def test_candidates_match
    each_input do |text|
      FILTERS.each do |mode, langs|
        assert_parity ruby(:candidates, text, mode, langs), PsychowlNative.candidates(text, mode, langs), text
      end
    end
  end

  def test_script_counts_match
    each_input do |text|
      assert_parity ruby(:script_counts, text), PsychowlNative.script_counts(text), text
      assert_parity ruby(:detect_script, text), PsychowlNative.detect_script(text), text
    end
  end

  def test_segments_match
    each_input do |text|
      assert_parity ruby(:sentences, text), PsychowlNative.sentences(text), text
      FILTERS.each do |mode, langs|
        assert_parity ruby(:segments, text, mode, langs), PsychowlNative.segments(text, mode, langs), text
      end
    end
  end

  def test_detect_many_matches
    texts = Samples.all.values.flatten + EXTRA

    FILTERS.each do |mode, langs|
      assert_parity ruby(:detect_many, texts, mode, langs), PsychowlNative.detect_many(texts, mode, langs), mode
    end
  end

  private

  def assert_parity(expected, actual, text)
    if expected.nil?
      assert_nil actual, text
    else
      assert_equal expected, actual, text
    end
  end

  def ruby(name, *) = Psychowl::RubyEngine.public_send(name, *)

  def each_input(&)
    samples = Samples.all.values.flatten
    prefixes = samples.flat_map { |sample| [5, 12, 30, 80].map { sample[0, it] } }
    (samples + prefixes + EXTRA).uniq.each(&)
  end
end
