{ pkgs ? null
}:

let inherit (import (import ../pins/nixpkgs) {}) lib; in

{
  imports = [
    ../modules/stakepool.nix
  ];

  boot.isContainer = true;

  services.tezos.nodes = [
    (rec { configDir = "/etc/nixos/secret/tezos-alphanet"; bakerDir = "${configDir}/baker"; } //
      lib.optionalAttrs (pkgs != null) { inherit pkgs; })
    (rec { configDir = "/etc/nixos/secret/tezos-mainnet"; bakerDir = "${configDir}/baker";
           network = "mainnet"; } //
      lib.optionalAttrs (pkgs != null) { inherit pkgs; })
  ];
}
