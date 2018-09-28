{ ...
}:

{
  imports = [
    ../modules/stakepool.nix
  ];

  boot.isContainer = true;

  services.tezos.nodes = [
    { configDir = "/etc/nixos/secret/tezos-alphanet"; }
    { configDir = "/etc/nixos/secret/tezos-mainnet"; network = "mainnet"; }
  ];
}
