#!/bin/sh
# Builds the precompiled gem for one Linux platform inside a ruby:4.0 image:
# a job container in the release workflow, or locally:
#
#   docker run --rm -v "$PWD:/src" -w /src ruby:4.0-trixie tools/build_native_gem.sh x86_64-linux-gnu
#
# trixie sets the glibc floor (2.41); alpine builds the musl gems.
set -eu
platform="$1"
upkg_installer="https://raw.githubusercontent.com/seuros/upkg/master/install.sh"

# Job containers get upkg from setup-upkg. Under plain docker run, install it:
# Debian images ship curl, Alpine only busybox wget. Download first: piped
# into sh, a failed download would run an empty script and succeed.
if ! command -v upkg >/dev/null 2>&1; then
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL -o /tmp/upkg-install.sh "$upkg_installer"
  else
    wget -qO /tmp/upkg-install.sh "$upkg_installer"
  fi
  sh /tmp/upkg-install.sh
fi

if [ -f /etc/alpine-release ]; then
  upkg install build-base clang-dev curl git
  # musl Rust links statically by default; a Ruby extension must be dynamic.
  export RUSTFLAGS="-C target-feature=-crt-static"
else
  upkg install clang libclang-dev curl git
fi

curl -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal --default-toolchain 1.99
. "$HOME/.cargo/env"

bundle install
bundle exec rake "gem:native[$platform]"
