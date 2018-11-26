{ bakerAddressAlias
, bakerDir
, configDir
, index
, kit
}:

''
set -e
set -u
set -o pipefail

if ! ${kit}/bin/tezos-client --base-dir "${bakerDir}" list known addresses | grep -E '^${bakerAddressAlias}: '; then
  ${kit}/bin/tezos-client --base-dir "${bakerDir}" gen keys "${bakerAddressAlias}"
  ${kit}/bin/tezos-client --base-dir "${bakerDir}" list known addresses | grep -E '^${bakerAddressAlias}: '
fi

exec ${kit}/bin/tezos-baker-002-PsYLVpVv --base-dir "${bakerDir}" --addr localhost --port ${toString (8732 + index)} \
  run with local node "${configDir}" "${bakerAddressAlias}"
''
