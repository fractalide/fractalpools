#! /usr/bin/env nix-shell
#! nix-shell --quiet -i bash -p bash gnused

set -u
set -e
set -o pipefail

nix_conf=/etc/nix/nix.conf
fracta_url=https://hydra.fractalide.com/
fracta_key="hydra.fractalide.com-1:EnGZBrRHPabgRET+umo2e+wNrw+c4QdbsxsnV5H7zs0="

reflex_url=https://nixcache.reflex-frp.org/
reflex_key="ryantrinkle.com-1:JJiAKaRv9mWgpVAz8dwewnZe0AzzEAzPkagE9SP5NWI="

nixos_url=https://cache.nixos.org/
nixos_key="cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="

mkdir -p $(dirname $nix_conf)
touch $nix_conf
{
  grep -vE 'substituters|public-keys|require-sigs' $nix_conf || true
  cat <<EOF
substituters = $nixos_url $fracta_url
trusted-substituters = $nixos_url $reflex_url $fracta_url
trusted-public-keys = $nixos_key $reflex_key $fracta_key
EOF
} > ${nix_conf}.new
mv ${nix_conf}.new $nix_conf
pkill -HUP nix-daemon || true
