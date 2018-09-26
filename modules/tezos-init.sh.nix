{ configDir
, kit
}:

''
set -e
set -u
set -o pipefail

if [ -e "${configDir}/identity.json" ]; then exit 0; fi

exec ${kit}/bin/tezos-node identity generate --data-dir "${configDir}"
''
