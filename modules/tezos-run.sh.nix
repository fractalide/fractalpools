{ configDir
, coreutils
, curl
, findutils
, gnugrep
, gnused
, index
, kit
, tzscanUrl
}:

''
set -e
set -u
set -o pipefail

ulimit -v unlimited  # tezos does sparse allocation of terabytes of vm

peerArgs=$(${curl}/bin/curl -S '${tzscanUrl}' | ${gnugrep}/bin/grep -Eo '::ffff:([0-9.:]+)' |
  ${gnused}/bin/sed -e 's/::ffff://' | ${coreutils}/bin/sort -u |
  ${findutils}/bin/xargs ${coreutils}/bin/printf -- '--peer=%s ')
exec ${kit}/bin/tezos-node run --data-dir "${configDir}" --rpc-addr localhost:${toString (8732 + index)} \
  --net-addr :${toString (9732 + index)} --connections 10 $peerArgs
''
