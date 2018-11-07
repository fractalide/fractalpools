{ bakerAddressAlias
, bakerDir
, bakerStatsExportDir
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

if ! [ -e "${configDir}/identity.json" ]; then
  ${runit}/bin/chpst -u "${user}" ${kit}/bin/tezos-node identity generate --data-dir "${configDir}"
fi

${if baking then ''
  mkdir -p "${bakerDir}"
  chown -R "${user}": "${bakerDir}"
  chmod 700 "${bakerDir}"

  mkdir -p "${bakerStatsExportDir}"
  chown -R "${user}": "${bakerStatsExportDir}"
'' else ""}
''
