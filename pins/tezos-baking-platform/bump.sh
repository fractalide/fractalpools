#! /usr/bin/env nix-shell
#! nix-shell -i bash -p bash findutils gawk git nix-prefetch-git

set -e
set -u
set -o pipefail

baseurl=https://gitlab.com
repo=obsidian.systems/tezos-baking-platform
branch=refs/heads/develop

SCRIPT_NAME=${BASH_SOURCE[0]##*/}

cd "${BASH_SOURCE[0]%$SCRIPT_NAME}"

if (( $# > 1 )); then
  echo "Usage: $SCRIPT_NAME [revision]"
  exit 2
fi

if (( $# == 1 )) && (( ${#1} == 40 )); then
  rev=$1
else if (( $# == 1)); then
  rev=$(git ls-remote $baseurl/$repo.git |
          awk '$2 == "'"$1"'" { print $1 }')
else
  rev=$(git ls-remote $baseurl/$repo.git |
          awk '$2 == "'"$branch"'" { print $1 }')
fi; fi

sha256=$(nix-prefetch-git --no-deepClone $baseurl/$repo.git $rev |
           awk -F '"'  '/sha256/ { print $4 }')

tee default.nix.new <<EOF
(import <nixpkgs> {}).fetchgit {
  url = "$baseurl/$repo";
  rev = "$rev";
  sha256 = "$sha256";
}
EOF

mv default.nix{.new,}
