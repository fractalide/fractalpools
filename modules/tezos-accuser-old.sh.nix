{ bakerDir
, index
, kit
}:

''
set -e
set -u
set -o pipefail

exec ${kit}/bin/tezos-accuser-002-PsYLVpVv --base-dir "${bakerDir}" --addr localhost --port ${toString (8732 + index)} \
  run
''
