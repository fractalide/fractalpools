#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")"

./support/utils/nix-build-travis-fold.sh -I pwd="$PWD" --no-out-link release.nix |& sed -e 's/travis_.*\r//'
