# frozen_string_literal: true

require_relative 'test_helper'

class CandidatesTest < Minitest::Test
  PORTUGUESE = 'Eu gostaria de reservar uma mesa para duas pessoas amanhã à noite, por favor.'

  def test_ranks_every_language_of_the_script
    candidates = Psychowl.candidates(PORTUGUESE)

    assert_equal(%w[por spa], candidates.first(2).map { |lang, _| lang.code })
    assert_equal 6, candidates.size
    assert_equal candidates.map(&:last).sort.reverse, candidates.map(&:last)
  end

  def test_limit
    assert_equal 2, Psychowl.candidates(PORTUGUESE, limit: 2).size
  end

  def test_single_language_script
    assert_equal [[Psychowl::Lang[:rus], 1.0]], Psychowl.candidates('Привет, как дела?')
  end

  def test_nothing_to_detect
    assert_empty Psychowl.candidates('1234')
  end
end
