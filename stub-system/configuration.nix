{ pkgs ? null
}:

let inherit (import (import ../pins/nixpkgs) {}) lib; in

{
  imports = [
    ../modules
  ];

  boot.isContainer = true;

  services.tezos.nodes = [
    (rec {
      configDir = "/etc/nixos/secret/tezos-alphanet";
      bakerDir = "${configDir}/baker";
      bakerStatsExportDir = "/var/log/tezos/alphanet/stats";
    } // lib.optionalAttrs (pkgs != null) { inherit pkgs; })
    (rec {
      configDir = "/etc/nixos/secret/tezos-mainnet";
      bakerDir = "${configDir}/baker";
      bakerStatsExportDir = "/var/log/tezos/mainnet/stats";
      network = "mainnet";
    } // lib.optionalAttrs (pkgs != null) { inherit pkgs; })
  ];
}
