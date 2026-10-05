# frozen_string_literal: true

require_relative 'lib/psychowl/version'

Gem::Specification.new do |spec|
  spec.name = 'psychowl'
  spec.version = Psychowl::VERSION
  spec.authors = ['Abdelkader Boudih']
  spec.email = ['terminale@gmail.com']

  spec.summary = 'Fast natural language and script detection. It knows what language you speak.'
  spec.description = 'Language and script detection with a pure Ruby engine and an optional Rust engine ' \
                     '(the psychowl crate) that gives identical results. Mixed-language segments, batch ' \
                     'detection, an ActiveModel validator and a CLI.'
  spec.homepage = 'https://github.com/seuros/psychowl'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.3.0'
  spec.required_rubygems_version = '>= 3.3.22'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['bug_tracker_uri'] = "#{spec.homepage}/issues"
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/master/CHANGELOG.md"
  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.metadata['cargo_crate_name'] = 'psychowl_native'
  spec.metadata['cargo_manifest_path'] = 'ext/psychowl_native/ffi/Cargo.toml'

  spec.files = Dir[
    'lib/**/*.{rb,yml}',
    'exe/*',
    'sig/**/*.rbs',
    'Cargo.toml',
    'Cargo.lock',
    'ext/psychowl_native/extconf.rb',
    'ext/psychowl_native/{core,ffi}/{Cargo.toml,build.rs,README.md}',
    'ext/psychowl_native/{core,ffi}/src/**/*.rs',
    'ext/psychowl_native/core/data/**/*',
    'README.md',
    'CHANGELOG.md',
    'LICENSE.txt'
  ]
  spec.bindir = 'exe'
  spec.executables = ['psychowl']
  spec.require_paths = ['lib']
  spec.extensions = ['ext/psychowl_native/extconf.rb']

  spec.add_dependency 'rb_sys', '~> 0.9.124'
end
