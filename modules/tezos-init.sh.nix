{ bakerDir
, baking
, configDir
, kit
, runit
, user
}:

''
set -e
set -u
set -o pipefail

export TEZOS_CLIENT_UNSAFE_DISABLE_DISCLAIMER=y

mkdir -p "${configDir}"
chown -R "${user}": "${configDir}"
chmod 700 "${configDir}"

${if baking then ''
  mkdir -p "${bakerDir}"
  chown -R "${user}": "${bakerDir}"
  chmod 700 "${bakerDir}"
'' else ""}

if [ -e "${configDir}/identity.json" ]; then exit 0; fi

exec ${runit}/bin/chpst -u "${user}" ${kit}/bin/tezos-node identity generate --data-dir "${configDir}"
''
