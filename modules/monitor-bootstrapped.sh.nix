{ bakerDir
, bash
, gnugrep
, index
, kit
, writeScript
}:

writeScript "monitor-bootstrapped.sh"
''
#!${bash}/bin/bash

set -euo pipefail

export TEZOS_CLIENT_UNSAFE_DISABLE_DISCLAIMER=y

while true; do
  ${kit}/bin/tezos-client --base-dir "${bakerDir}" --addr localhost --port ${toString (8732 + index)} \
    rpc get /monitor/bootstrapped |& grep '"block"' && break
  sleep 3
done
''
