# frozen_string_literal: true

# The extension is optional: when it cannot be built, write a do-nothing
# Makefile so `gem install` succeeds and the pure Ruby engine is used.
def skip_native(reason)
  warn "psychowl: #{reason}; using the pure Ruby engine"
  File.write('Makefile', "all:\n\t@:\ninstall:\n\t@:\nclean:\n\t@:\n")
  exit 0
end

def command?(command) = system(command, out: File::NULL, err: File::NULL)

# rb_sys writes a GNU Makefile; RubyGems runs the system make (BSD make here).
BSD = RUBY_PLATFORM.include?('bsd')

skip_native("native extensions are not supported on #{RUBY_ENGINE}") unless RUBY_ENGINE == 'ruby'
skip_native('Cargo not found (install Rust from https://rustup.rs)') unless command?('cargo --version')
skip_native('GNU make not found (pkg install gmake)') if BSD && !command?('gmake --version')

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

# BSD make reads BSDmakefile first (GNU make ignores it): delegate to gmake.
if BSD
  File.write('BSDmakefile', <<~MAKE)
    GMAKE_VARS =
    .for var in DESTDIR sitearchdir sitelibdir
    .if defined(${var})
    GMAKE_VARS += ${var}="${${var}}"
    .endif
    .endfor

    all:
    \tgmake -f Makefile ${GMAKE_VARS}

    .DEFAULT:
    \tgmake -f Makefile ${GMAKE_VARS} $@
  MAKE
end
