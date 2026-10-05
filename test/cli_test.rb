# frozen_string_literal: true

require_relative 'test_helper'
require 'json'
require 'open3'
require 'rbconfig'

class CliTest < Minitest::Test
  EXE = File.expand_path('../exe/psychowl', __dir__)
  LIB = File.expand_path('../lib', __dir__)

  def run_cli(*, input:)
    Open3.capture3(RbConfig.ruby, '-I', LIB, EXE, *, stdin_data: input)
  end

  def test_detects_stdin
    out, _err, status = run_cli(input: '¿Dónde está la biblioteca? Estoy buscando un libro.')

    assert_predicate status, :success?
    assert_equal 'spa', out.split("\t").first
  end

  def test_json_lines
    out, _err, status = run_cli('--lines', '--json', input: "Das ist ein sehr guter Satz auf Deutsch.\n12345\n")

    assert_predicate status, :success?
    assert_equal(['deu', nil], JSON.parse(out).map { it&.fetch('lang') })
  end

  def test_exit_status_when_nothing_is_detected
    out, _err, status = run_cli(input: '12345')

    assert_equal 1, status.exitstatus
    assert_equal "unknown\n", out
  end

  def test_rejects_unknown_language
    _out, err, status = run_cli('--allow', 'klingon', input: 'text')

    assert_equal 2, status.exitstatus
    assert_match(/unsupported language/, err)
  end
end
