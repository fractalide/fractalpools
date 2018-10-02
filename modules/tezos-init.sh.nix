{ configDir
, kit
, runit
, user
}:

''
set -e
set -u
set -o pipefail

mkdir -p "${configDir}"
chown -R "${user}": "${configDir}"
chmod 700 "${configDir}"

if [ -e "${configDir}/identity.json" ]; then exit 0; fi

exec ${runit}/bin/chpst -u "${user}" ${kit}/bin/tezos-node identity generate --data-dir "${configDir}"
''
