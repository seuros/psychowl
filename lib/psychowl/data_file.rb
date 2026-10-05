# frozen_string_literal: true

module Psychowl
  # Reads the plain-text data files. No load-time side effects, so the data
  # tools can use it before the tables exist.
  module DataFile
    # Lines of a file, without blank lines and # comments.
    def self.lines(path)
      File.readlines(path, chomp: true, encoding: Encoding::UTF_8).reject do |line|
        line.empty? || line.start_with?('#')
      end
    end
  end
end
