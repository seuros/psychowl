# frozen_string_literal: true

require_relative 'test_helper'

# The README's "The owl has heard things" table promises every line is
# detected correctly at full confidence. Keep the owl honest.
class ReadmeTest < Minitest::Test
  README = File.expand_path('../README.md', __dir__)

  def gallery
    rows = File.readlines(README, chomp: true).grep(/\A\| (\w{3}) \| /)
    rows.map { |row| row.split(' | ').values_at(0, 1).map { |cell| cell.delete_prefix('| ') } }
  end

  def test_gallery_lists_every_language
    assert_equal Psychowl::Lang.all.map(&:code).sort, gallery.map(&:first).sort
  end

  def test_gallery_lines_are_detected_at_full_confidence
    gallery.each do |code, text|
      info = Psychowl.detect(text)

      assert_equal code, info&.lang&.code, text
      assert_in_delta 1.0, info.confidence, 0.0, text
    end
  end
end
