{ pkgs
}:

{
  imports = [
    ../modules/stakepool.nix
  ];

  boot.isContainer = true;

  services.tezos.nodes = [
    { configDir = "/etc/nixos/secret/tezos-alphanet"; inherit pkgs; }
    { configDir = "/etc/nixos/secret/tezos-mainnet"; network = "mainnet"; inherit pkgs; }
  ];
}
