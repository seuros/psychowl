# frozen_string_literal: true

# Compares the pure Ruby engine with the Rust one.
#   bundle exec rake compile && bundle exec ruby bench/engines.rb

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'psychowl'

def realtime
  start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  yield
  Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
end

abort 'compile the native extension first (rake compile)' unless Psychowl.backend == :native

samples = Dir[File.join(Psychowl::Tables::DIR, '../tests/samples/*.txt')].flat_map do |path|
  File.readlines(path, chomp: true).reject { |line| line.start_with?('#') }
end
latin = samples.grep(/\A[[:ascii:]À-ž\s[:punct:]]+\z/)

cases = {
  'short sentence' => [latin.first, 2_000],
  'paragraph (~1 KB)' => [latin.join(' ')[0, 1_000], 500],
  'document (~100 KB)' => ["#{latin.join(' ')} " * 40, 5]
}

ruby_detect = Psychowl::RubyEngine.method(:detect)
native_detect = PsychowlNative.method(:detect)

puts '                               ruby       native  speedup'
cases.each do |name, (text, iterations)|
  ruby = realtime { iterations.times { ruby_detect.call(text, 0, []) } } / iterations
  native = realtime { iterations.times { native_detect.call(text, 0, []) } } / iterations
  puts format('%-22s %10.1fµs %10.1fµs %7.1fx', name, ruby * 1e6, native * 1e6, ruby / native)
end

batch = samples * 250
ruby_many = Psychowl::RubyEngine.method(:detect_many)
ruby = realtime { ruby_many.call(batch, 0, []) }
native = realtime { PsychowlNative.detect_many(batch, 0, []) }
puts format('%-22s %10.1fms %10.1fms %7.1fx', "detect_many (#{batch.size})", ruby * 1e3, native * 1e3, ruby / native)
