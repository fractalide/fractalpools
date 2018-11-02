{ bakerAddressAlias
, bakerDir
, bakerStatsExportDir
, gawk
, index
, jq
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

function jq() {
  ${jq}/bin/jq "$@"
}

address=$(client show address "${bakerAddressAlias}" | ${gawk}/bin/awk '$1 == "Hash:" { print $2 }')
head=$(client rpc get /chains/main/blocks/head/hash | jq . -r)

block=$head
blocks=( $head )

while true; do
  block_dir="${bakerStatsExportDir}"/block/$block
  if [ ! -d "$block_dir" ]; then
    mkdir -p "$block_dir".new
    client rpc get /chains/main/blocks/$block/helpers/current_level > "$block_dir".new/current_level.json
    client rpc get /chains/main/blocks/$block/context/delegates/$address | ( jq . 2>/dev/null || echo '[]' ) > "$block_dir".new/delegate.json
    client rpc get /chains/main/blocks/$block/helpers/baking_rights?delegate=$address > "$block_dir".new/baking_rights.json
    client rpc get /chains/main/blocks/$block/helpers/endorsing_rights?delegate=$address > "$block_dir".new/endorsing_rights.json
    mv "$block_dir".new "$block_dir"
  fi

  cycle=$(jq -r .cycle < "$block_dir"/current_level.json)
  rm -f "${bakerStatsExportDir}"/cycle/$cycle
  mkdir -p "${bakerStatsExportDir}"/cycle
  ln -s ../block/$block "${bakerStatsExportDir}"/cycle/$cycle
  (( cycle == 0 )) && break

  cycle_position=$(jq -r .cycle_position < "$block_dir"/current_level.json)
  block=$(client rpc get /chains/main/blocks/$block~$((cycle_position + 1))/hash | jq . -r)
  blocks+=( $block )
done

printf "%s\n" "''${blocks[@]}" > "${bakerStatsExportDir}"/blocks

for i in delegate baking_rights endorsing_rights; do
  rm -f "${bakerStatsExportDir}"/$i.json
  ln -s block/$head/$i.json "${bakerStatsExportDir}"/$i.json
done
''
