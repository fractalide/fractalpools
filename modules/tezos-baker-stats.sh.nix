{ bakerAddressAlias
, bakerDir
, bakerStatsExportDir
, gawk
, index
, kit
}:

''
set -e
set -u
set -o pipefail

export TEZOS_CLIENT_UNSAFE_DISABLE_DISCLAIMER=y

function client() {
  ${kit}/bin/tezos-client --base-dir '${bakerDir}' --addr localhost --port ${toString (8732 + index)} "$@"
}

address=$(client show address "${bakerAddressAlias}" | ${gawk}/bin/awk '$1 == "Hash:" { print $2 }')

client rpc get /chains/main/blocks/head/context/delegates/$address > "${bakerStatsExportDir}"/delegate.json.new
client rpc get /chains/main/blocks/head/helpers/baking_rights?delegate=$address > "${bakerStatsExportDir}"/baking_rights.json.new
client rpc get /chains/main/blocks/head/helpers/endorsing_rights?delegate=$address > "${bakerStatsExportDir}"/endorsing_rights.json.new

for i in delegate baking_rights endorsing_rights; do
  mv "${bakerStatsExportDir}"/$i.json{.new,}
done
''
