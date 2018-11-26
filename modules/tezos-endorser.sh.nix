{ bakerAddressAlias
, bakerDir
, index
, kit
}:

''
set -e
set -u
set -o pipefail

exec ${kit}/bin/tezos-endorser-003-PsddFKi3 --base-dir "${bakerDir}" --addr localhost --port ${toString (8732 + index)} \
  run "${bakerAddressAlias}"
''
