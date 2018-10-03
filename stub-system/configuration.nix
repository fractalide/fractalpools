{ pkgs ? null
}:

let inherit (import (import ../pins/nixpkgs) {}) lib; in

{
  imports = [
    ../modules/stakepool.nix
  ];

  boot.isContainer = true;

  services.tezos.nodes = [
    ({ configDir = "/etc/nixos/secret/tezos-alphanet"; } //
      lib.optionalAttrs (pkgs != null) { inherit pkgs; })
    ({ configDir = "/etc/nixos/secret/tezos-mainnet"; network = "mainnet"; } //
      lib.optionalAttrs (pkgs != null) { inherit pkgs; })
  ];
}
