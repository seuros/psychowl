# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'minitest/test_task'

GEMSPEC = Gem::Specification.load('psychowl.gemspec')
CARGO_MANIFEST = 'Cargo.toml'
# RbSys::ExtensionTask would point cargo at ext_dir (where the graceful
# extconf.rb lives); the crate itself is in ffi/.
ENV['RB_SYS_CARGO_MANIFEST_DIR'] ||= File.expand_path('ext/psychowl_native/ffi', __dir__)

Minitest::TestTask.create(:test) do |t|
  t.test_globs = ['test/**/*_test.rb']
end

begin
  require 'rb_sys/extensiontask'

  RbSys::ExtensionTask.new('psychowl_native', GEMSPEC) do |ext|
    ext.ext_dir = 'ext/psychowl_native'
    ext.lib_dir = 'lib/psychowl'
    ext.cross_compile = true
    # rb_sys cross toolchains; FreeBSD has none and builds from source.
    ext.cross_platform = %w[
      aarch64-linux aarch64-linux-musl arm64-darwin
      x86_64-darwin x86_64-linux x86_64-linux-musl
    ]
  end
rescue LoadError
  desc 'Native extension unavailable (rb_sys missing); pure Ruby only'
  task :compile
end

namespace :test do
  desc 'Run the suite on the pure Ruby engine'
  task :ruby do
    sh({ 'DISABLE_PSYCHOWL_NATIVE' => '1' }, FileUtils::RUBY, '-Ilib', '-Itest', '-e',
       "Dir['test/**/*_test.rb'].each { |f| require File.expand_path(f) }")
  end

  desc 'Compile and run the suite on the Rust engine'
  task native: :compile do
    Rake::Task[:test].invoke
  end

  desc 'cargo test for the psychowl crate'
  task :rust do
    sh 'cargo', 'test', '--manifest-path', CARGO_MANIFEST, '--package', 'psychowl'
  end

  desc 'Both engines, plus the Rust crate'
  task all: %i[rust ruby native]
end

namespace :psychowl do
  desc 'Train a trigram profile from corpus/<code>.txt (or CORPUS=path)'
  task :train, [:code] do |_task, args|
    abort 'usage: rake "psychowl:train[code]"' unless args[:code]

    sh FileUtils::RUBY, 'tools/train_profile.rb', args[:code], *ENV.fetch('CORPUS', nil)
  end
end

desc 'dictator, cargo fmt --check and clippy'
task :lint do
  sh 'dictator', 'lint', '.'
  sh 'cargo', 'fmt', '--manifest-path', CARGO_MANIFEST, '--all', '--check'
  sh 'cargo', 'clippy', '--manifest-path', CARGO_MANIFEST, '--workspace', '--all-targets', '--', '-D', 'warnings'
end

task default: 'test:all'
