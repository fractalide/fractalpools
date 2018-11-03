{ bakerAddressAlias
, bakerDir
, bakerStatsExportDir
, coreutils
, findutils
, gawk
, gnugrep
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

delegate_default='{
  "balance": "0", "frozen_balance": "0", "frozen_balance_by_cycle": [],
  "staking_balance": "0",
  "delegated_contracts": [],
  "delegated_balance": "0", "deactivated": false,
  "grace_period": 77
}'

fractalpools_version=2

while true; do
  block_dir="${bakerStatsExportDir}"/block/$block
  if [ ! -d "$block_dir" ] || [ ! -e "$block_dir"/fractalpools_version ] ||
     (( $(${coreutils}/bin/cat "$block_dir"/fractalpools_version) < $fractalpools_version )); then
    ${coreutils}/bin/mkdir -p "$block_dir".new
    client rpc get /chains/main/blocks/$block/helpers/current_level > "$block_dir".new/current_level.json
    client rpc get /chains/main/blocks/$block/context/delegates/$address | ( jq . 2>/dev/null || echo "$delegate_default" ) > "$block_dir".new/delegate.json
    client rpc get /chains/main/blocks/$block/helpers/baking_rights?delegate=$address > "$block_dir".new/baking_rights.json
    client rpc get /chains/main/blocks/$block/helpers/endorsing_rights?delegate=$address > "$block_dir".new/endorsing_rights.json
    echo '{}' > "$block_dir".new/stakes.json
    for staker in $(jq -r '.delegated_contracts[]' < "$block_dir".new/delegate.json); do
      balance=$(client rpc get /chains/main/blocks/head/context/contracts/$staker/balance)  # including the quotation marks
      ${coreutils}/bin/cat "$block_dir".new/stakes.json | jq ". += { \"$staker\": $balance }" > "$block_dir".new/stakes.json.new
      ${coreutils}/bin/mv "$block_dir".new/stakes.json.new "$block_dir".new/stakes.json
    done
    echo $fractalpools_version > "$block_dir".new/fractalpools_version
    ${coreutils}/bin/rm -rf "$block_dir"
    ${coreutils}/bin/mv "$block_dir".new "$block_dir"
  fi

  cycle=$(jq -r .cycle < "$block_dir"/current_level.json)
  ${coreutils}/bin/rm -f "${bakerStatsExportDir}"/cycle/$cycle
  ${coreutils}/bin/mkdir -p "${bakerStatsExportDir}"/cycle
  ${coreutils}/bin/ln -s ../block/$block "${bakerStatsExportDir}"/cycle/$cycle
  (( cycle == 0 )) && break

  cycle_position=$(jq -r .cycle_position < "$block_dir"/current_level.json)
  block=$(client rpc get /chains/main/blocks/$block~$((cycle_position + 1))/hash | jq . -r)
  blocks+=( $block )
done

printf "%s\n" "''${blocks[@]}" > "${bakerStatsExportDir}"/blocks

for i in delegate baking_rights endorsing_rights; do
  ${coreutils}/bin/rm -f "${bakerStatsExportDir}"/$i.json
  ${coreutils}/bin/ln -s block/$head/$i.json "${bakerStatsExportDir}"/$i.json
done

${findutils}/bin/find "${bakerStatsExportDir}"/block -maxdepth 1 -path "${bakerStatsExportDir}/block/*" -print0 |
  ${gnugrep}/bin/grep -zZvFf "${bakerStatsExportDir}"/blocks |
  ${findutils}/bin/xargs -0 rm -rf
''
