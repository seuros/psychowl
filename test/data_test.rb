# frozen_string_literal: true

require_relative 'test_helper'

# Guards the shared data files the Rust crate also compiles in.
class DataTest < Minitest::Test
  TABLES = Psychowl::Tables

  def test_languages_are_sorted_and_unique
    codes = TABLES::LANGUAGES.map(&:first)

    assert_equal codes.sort.uniq, codes
    assert_equal codes.size, TABLES::LANGUAGES.map { it[1] }.uniq.size
  end

  def test_script_ranges_are_disjoint
    rows = Psychowl::DataFile.lines(File.join(TABLES::DIR, 'scripts.tsv'))
    ranges = rows.flat_map { |row| row.split("\t")[2].split(',').map { code_points(it) } }.sort

    ranges.each_cons(2) { |(_, high), (low, _)| assert_operator low, :>, high }
  end

  def test_shared_scripts_have_profiles_and_alphabets
    TABLES::SCRIPTS.each do |script|
      next if script.languages.size < 2 || script.name == 'Han'

      script.languages.each do |language|
        code = TABLES::LANGUAGES[language][0]

        assert TABLES::TRIGRAMS.key?(language), "#{code} needs trigrams/#{code}.txt"
        assert TABLES::ALPHABETS.key?(language), "#{code} needs an alphabets.tsv entry"
      end
    end
  end

  def test_profiles_hold_300_unique_trigrams
    TABLES::TRIGRAMS.each do |language, trigrams|
      code = TABLES::LANGUAGES[language][0]

      assert_equal 300, trigrams.size, code
      assert_equal trigrams.size, trigrams.uniq.size, code
      assert_empty trigrams.reject { it.length == 3 }, code
    end
  end

  private

  # "0400-0484" -> [0x400, 0x484]; "1D2B" -> [0x1D2B, 0x1D2B]
  def code_points(range)
    low, high = range.split('-').map { it.to_i(16) }
    [low, high || low]
  end
end
