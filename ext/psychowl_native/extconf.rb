# frozen_string_literal: true

# The native extension is an optional speedup. Whenever it cannot be built,
# write a do-nothing Makefile so `gem install` still succeeds and Psychowl
# runs on its pure Ruby engine.
def skip_native(reason)
  warn "psychowl: #{reason}; using the pure Ruby engine"
  File.write('Makefile', "all:\n\t@:\ninstall:\n\t@:\nclean:\n\t@:\n")
  exit 0
end

skip_native("native extensions are not supported on #{RUBY_ENGINE}") unless RUBY_ENGINE == 'ruby'
skip_native('Cargo not found (install Rust from https://rustup.rs)') unless system('cargo --version', out: File::NULL,
                                                                                                      err: File::NULL)

begin
  require 'mkmf'
  require 'rb_sys/mkmf'
rescue LoadError => e
  skip_native("rb_sys is unavailable (#{e.message})")
end

create_rust_makefile('psychowl/psychowl_native') do |r|
  r.ext_dir = 'ffi'
  r.profile = ENV.fetch('RB_SYS_CARGO_PROFILE', :release).to_sym
end
