{ backerei
, bakerDir
, bash
, coreutils
, findutils
, gawk
, gnugrep
, index
, jq
, kit
, tcl
, writeScript
}:

writeScript "tezos-baker-stats.sh"
''
#!${bash}/bin/bash
set -e
set -u
set -o pipefail

export TEZOS_CLIENT_UNSAFE_DISABLE_DISCLAIMER=y
NUM_REQUIRED_PARAMS=3

if (( $# < 3 )); then
  echo >&2 "Usage: ''${BASH_SOURCE[0]#*/} <output directory> <account address or name> <fee percentage> [<init_parameter_0> [ ... <init_parameter_n>]]"
  echo >&2 ""
  echo >&2 "The init parameters are sent unaltered to backerei init."

  exit 2
fi

outputDir=$1
addressOrName=$2
bakerFee=$3
argv=( "$@" )
init_parameters=( "''${argv[@]:$NUM_REQUIRED_PARAMS}" )
printf >&2 "init_parameters "
printf >&2 "'%s' " "''${init_parameters[@]}"
echo >&2

function client() {
  ${kit}/bin/tezos-client --base-dir '${bakerDir}' --addr localhost --port ${toString (8732 + index)} "$@"
}

function jq() {
  ${jq}/bin/jq "$@"
}

if (( ''${#addressOrName} == 36 )) && [[ ''${addressOrName:0:3} = "tz1" ]]; then
  address=$addressOrName
else
  address=$(client show address "$addressOrName" | ${gawk}/bin/awk '$1 == "Hash:" { print $2 }')
fi

head=$(client rpc get /chains/main/blocks/head/hash | jq . -r)

block=$head
blocks=( $head )

fractalpools_version=4
first_delegate_cycle=""

while true; do
  block_dir="$outputDir"/block/$block
  if [ ! -d "$block_dir" ] || [ ! -e "$block_dir"/fractalpools_version ] ||
     (( $(${coreutils}/bin/cat "$block_dir"/fractalpools_version) != $fractalpools_version )); then
    ${coreutils}/bin/mkdir -p "$block_dir".new
    client rpc get /chains/main/blocks/$block/helpers/current_level > "$block_dir".new/current_level.json
    delegate=$(client rpc get /chains/main/blocks/$block/context/delegates/$address)
    # Invalid delegate info? Delegate didn't yet exist then.
    jq . >/dev/null 2>/dev/null <<< "$delegate" && echo "$delegate" > "$block_dir".new/delegate.json
    echo $fractalpools_version > "$block_dir".new/fractalpools_version
    ${coreutils}/bin/rm -rf "$block_dir"
    ${coreutils}/bin/mv "$block_dir".new "$block_dir"
  fi

  cycle=$(jq -r .cycle < "$block_dir"/current_level.json)
  ${coreutils}/bin/rm -f "$outputDir"/cycle/$cycle
  ${coreutils}/bin/mkdir -p "$outputDir"/cycle
  ${coreutils}/bin/ln -s ../block/$block "$outputDir"/cycle/$cycle
  if [ ! -e "$block_dir"/delegate.json ] || (( cycle == 0 )); then
    break
  fi

  first_delegate_cycle=$cycle
  cycle_position=$(jq -r .cycle_position < "$block_dir"/current_level.json)
  block=$(client rpc get /chains/main/blocks/$block~$((cycle_position + 1))/hash | jq . -r)
  blocks+=( $block )
done

printf "%s\n" "''${blocks[@]}" > "$outputDir"/blocks

if [[ -n $first_delegate_cycle ]]; then
  backereiConfDir=$(${coreutils}/bin/mktemp --tmpdir --directory backerei-XXXXXXXXXXXX)
  trap "rm -r '$backereiConfDir'" EXIT

  ${backerei}/bin/backerei --config "$backereiConfDir/backerei.yaml" init \
    --tz1 $address --port ${toString (8732 + index)} \
    --client-path '${kit}/bin/tezos-client' --client-config-file '${bakerDir}/config' \
    --database-path "$outputDir"/backerei.json \
    --starting-cycle $((first_delegate_cycle + 8)) \
    --fee "$bakerFee"%100 \
    "''${init_parameters[@]}"

  ${backerei}/bin/backerei --config "$backereiConfDir/backerei.yaml" payout <<< ""
fi

for i in delegate; do
  ${coreutils}/bin/rm -f "$outputDir"/$i.json
  ${coreutils}/bin/ln -s block/$head/$i.json "$outputDir"/$i.json
done

${findutils}/bin/find "$outputDir"/block -maxdepth 1 -path "$outputDir/block/*" -print0 |
  ${gnugrep}/bin/grep -zZvFf "$outputDir"/blocks |
  ${findutils}/bin/xargs -0 ${coreutils}/bin/rm -rf
''
