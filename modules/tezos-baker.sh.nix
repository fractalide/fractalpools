{ bakerDir
, configDir
, index
, kit
}:

''
set -e
set -u
set -o pipefail

exec ${kit}/bin/tezos-baker-002-PsYLVpVv --base-dir "${bakerDir}" --addr localhost --port ${toString (8732 + index)} \
  run with local node "${configDir}"
''
