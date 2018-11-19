#!/usr/bin/env nix-shell
#! nix-shell --quiet --pure -p bash gawk git nix -i bash

set -euo pipefail

BASE_URL=https://github.com
OWNER=cryptiumlabs
REPO=backerei
DEFAULT_REV=refs/heads/master

cd "$(dirname "${BASH_SOURCE[0]}")"

rev=${1:-$DEFAULT_REV}

if (( ${#rev} != 40 )); then
  rev=$(git ls-remote $BASE_URL/$OWNER/$REPO | awk '$2 == "'"$rev"'" { print $1 }')
fi

full_url=$BASE_URL/$OWNER/$REPO/archive/$rev.tar.gz
hash=$(nix-prefetch-url --unpack --name source $full_url)
cat > default.json.new <<EOM
{
  "owner": "$OWNER",
  "repo": "$REPO",
  "rev": "$rev",
  "sha256": "$hash"
}
EOM
mv default.json{.new,}
