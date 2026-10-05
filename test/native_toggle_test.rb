# frozen_string_literal: true

require_relative 'test_helper'
require 'open3'
require 'rbconfig'

# DISABLE_PSYCHOWL_NATIVE must only switch the extension off when it holds a
# value: CI matrices often set it to an empty string.
class NativeToggleTest < Minitest::Test
  LIB = File.expand_path('../lib', __dir__)

  def backend_with(env)
    out, status = Open3.capture2(env, RbConfig.ruby, '-I', LIB, '-rpsychowl', '-e', 'print Psychowl.backend')

    assert_predicate status, :success?
    out
  end

  def setup
    skip 'native extension not built' unless native_built?
  end

  # Independent of the environment logic under test.
  def native_built?
    !Dir[File.join(LIB, 'psychowl', '**', "psychowl_native.#{RbConfig::CONFIG['DLEXT']}")].empty?
  end

  def test_empty_value_keeps_native
    assert_equal 'native', backend_with('DISABLE_PSYCHOWL_NATIVE' => '', 'DISABLE_MATRYOSHKA_NATIVE' => '')
  end

  def test_value_disables_native
    assert_equal 'ruby', backend_with('DISABLE_PSYCHOWL_NATIVE' => '1')
    assert_equal 'ruby', backend_with('DISABLE_MATRYOSHKA_NATIVE' => '1', 'DISABLE_PSYCHOWL_NATIVE' => '')
  end
end
