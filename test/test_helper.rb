# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'psychowl'
require 'minitest/autorun'

warn "psychowl backend: #{Psychowl.backend}"

module Samples
  DIR = File.expand_path('../ext/psychowl_native/core/tests/samples', __dir__)

  # {"eng" => ["sample", ...], ...}
  def self.all
    @all ||= Dir[File.join(DIR, '*.txt')].to_h do |path|
      [File.basename(path, '.txt'), Psychowl::DataFile.lines(path)]
    end
  end
end
