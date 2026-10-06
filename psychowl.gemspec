# frozen_string_literal: true

require_relative 'lib/psychowl/version'

Gem::Specification.new do |spec|
  # Set by `rake gem:native`: the gem then carries the prebuilt extension for
  # that platform. Unset, it is the pure Ruby gem (Windows, JRuby, ...).
  platform = ENV.fetch('PSYCHOWL_PLATFORM', nil)

  spec.name = 'psychowl'
  spec.version = Psychowl::VERSION
  spec.authors = ['Abdelkader Boudih']
  spec.email = ['terminale@gmail.com']

  spec.summary = 'Fast natural language and script detection. It knows what language you speak.'
  spec.description = 'Language and script detection with a Rust engine, precompiled for Linux, macOS and ' \
                     'FreeBSD, and an identical pure Ruby engine everywhere else. Mixed-language segments, ' \
                     'batch detection, an ActiveModel validator and a CLI.'
  spec.homepage = 'https://github.com/seuros/psychowl'
  spec.license = 'MIT'

  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['bug_tracker_uri'] = "#{spec.homepage}/issues"
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/master/CHANGELOG.md"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir[
    'lib/**/*.{rb,yml}',
    'exe/*',
    'ext/psychowl_native/core/data/**/*',
    'README.md',
    'CHANGELOG.md',
    'LICENSE.txt'
  ]
  spec.bindir = 'exe'
  spec.executables = ['psychowl']
  spec.require_paths = ['lib']

  if platform
    spec.platform = Gem::Platform.new(platform)
    spec.files += Dir['lib/psychowl/[0-9]*/psychowl_native.{so,bundle}']
    # The binary is built for one Ruby ABI; newer Rubies get the pure Ruby gem.
    spec.required_ruby_version = ['>= 4.0', '< 4.1.dev']
  else
    spec.required_ruby_version = '>= 4.0'
  end
end
