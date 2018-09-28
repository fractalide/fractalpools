{ config, lib, pkgs, ...  }:

with lib;

let
  cfg = config.services.tezos;
  tezos-baking-platform = pkgs.callPackage (import ../pins/tezos-baking-platform) {};
  tezosNode = types.submodule { options = {
    network = mkOption {
      default = "alphanet";
      type = types.enum (builtins.attrNames tezos-baking-platform.tezos);
      description = "Which tezos network to run on";
    };
    configDir = mkOption {
      type = types.str;
      description = "Where to store node state, e.g. identity secret, entire blockchain.";
    };
    baking.enable = mkOption {
      default = true;
      type = types.bool;
      description = "Whether to configure and run baking and endorsing";
    };
  };};
  makeServices = nodes: makeServiceEntries 0 nodes {};
  makeServiceEntries = index: nodes: done: if nodes == [] then done else let
    current = builtins.head nodes;
    name = "tezos-${current.network}-init-${toString index}";
    value = {
      description = "Tezos ${current.network} initialization";
      script = import ./tezos-init.sh.nix {
        inherit (tezos-baking-platform.tezos."${current.network}") kit;
        inherit (current) configDir;
      };
      wantedBy = [ "multi-user.target" ];  # Only until we get other units in here depending on it
      after = [ "local-fs.target" ];
      serviceConfig = {
        Type = "oneshot";
      };
    };
  in
    makeServiceEntries (index + 1) (builtins.tail nodes) (done // { "${name}" = value; });
in
{
  options = {
    services.tezos.nodes = mkOption {
      default = [];
      type = types.listOf tezosNode;
      description = "List of Tezos nodes";
    };
  };
  config = lib.mkIf (cfg.nodes != []) {
    systemd.services = makeServices cfg.nodes;
    assertions = [
      { assertion = pkgs.stdenv.isLinux; message = "Service only defined for Linux systems."; }
    ];
  };
}
