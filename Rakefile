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

namespace :gem do
  desc 'Build the pure Ruby gem (Windows, JRuby, TruffleRuby, anything unsupported)'
  task ruby: :build

  # A task argument, not PSYCHOWL_PLATFORM: set for the whole rake process, that
  # would turn the gemspec into a platform gem for compile's bundler/setup too.
  desc 'Build the precompiled gem for this machine (gem:native[platform] overrides the platform)'
  task :native, [:platform] => :compile do |_task, args|
    ruby_abi = RUBY_VERSION[/\A\d+\.\d+/]
    binary = "psychowl_native.#{RbConfig::CONFIG['DLEXT']}"
    staged = "lib/psychowl/#{ruby_abi}/#{binary}"
    local = Gem::Platform.local
    # A darwin version would limit the gem to that one macOS release.
    platform = args[:platform] || (local.os == 'darwin' ? "#{local.cpu}-darwin" : local.to_s)

    mkdir_p File.dirname(staged)
    cp "lib/psychowl/#{binary}", staged
    mkdir_p 'pkg'
    Bundler.with_unbundled_env do
      sh({ 'PSYCHOWL_PLATFORM' => platform }, 'gem', 'build', 'psychowl.gemspec',
         '--output', "pkg/psychowl-#{GEMSPEC.version}-#{platform}.gem")
    end
  ensure
    rm_rf File.dirname(staged) if staged
  end

  desc 'Push every built gem for this version to RubyGems'
  task :push_all do
    gems = Dir["pkg/psychowl-#{GEMSPEC.version}*.gem"]
    abort "no gems in pkg/ for #{GEMSPEC.version}" if gems.empty?

    gems.each { sh 'gem', 'push', it }
  end
end

task default: 'test:all'

# Bundler's release would push only the pure Ruby gem.
Rake::Task['release'].clear
desc 'Release: tag, then push the gems built by the release workflow (rake gem:push_all)'
task :release do
  abort 'Use the release workflow, then `rake gem:push_all` with every gem in pkg/'
end
