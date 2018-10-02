{ config, lib, ... }:

let pkgs_ = import ../pins/nixpkgs {}; in

with lib;

let
  cfg = config.services.tezos;
  defaultUser = "tezos";
  tezosNode = types.submodule { options = {
    network = mkOption {
      default = "alphanet";
      type = let tezos-baking-platform = import (import ../pins/tezos-baking-platform) {}; in
        types.enum (builtins.attrNames tezos-baking-platform.tezos);
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
    pkgs = mkOption {
      default = pkgs_;
      description = "The nixpkgs to be used for building tools.";
    };
    user = mkOption {
      default = defaultUser;
      type = types.str;
      description = "The user under which to run the service. If left to the default, the user will be created automatically, otherwise it needs to be explicitly created.";
    };
  };};
  tzscanUrls = let path = "v1/network?state=running&p=0&number=50"; in {
    alphanet = "http://alphanet-api.tzscan.io/${path}";
    mainnet = "http://api2.tzscan.io/${path}";
    zeronet = "http://zeronet-api.tzscan.io/${path}";
  };
  makeServices = nodes: makeServiceEntries 0 nodes {};
  makeServiceEntries = index: nodes: done: if nodes == [] then done else let
    current = builtins.head nodes;
    tzscanUrl = tzscanUrls."${current.network}";
    pkgs = current.pkgs;
    tezos-baking-platform = pkgs.callPackage (import ../pins/tezos-baking-platform) {};
    init-name = "tezos-${current.network}-init-${toString index}";
    init-value = {
      description = "Tezos ${current.network} initialization";
      script = import ./tezos-init.sh.nix {
        inherit (tezos-baking-platform.tezos."${current.network}") kit;
        inherit (current) configDir;
      };
      after = [ "local-fs.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
    };
    run-name = "tezos-${current.network}-run-${toString index}";
    run-value = {
      description = "Tezos ${current.network} node";
      script = import ./tezos-run.sh.nix {
        inherit (tezos-baking-platform.tezos."${current.network}") kit;
        inherit (current) configDir;
        inherit index tzscanUrl;
        inherit (pkgs) coreutils curl findutils gnugrep gnused;
      };
      wantedBy = [ "multi-user.target" ];
      after = [ "${init-name}.service" ];
      wants = [ "${init-name}.service" ];
    };
  in
    makeServiceEntries (index + 1) (builtins.tail nodes) (done // {
      "${init-name}" = init-value;
      "${run-name}" = run-value;
    });
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
    users = lib.mkIf (any (node: node.user == defaultUser) cfg.nodes) {
      groups."${defaultUser}" = {};
      users."${defaultUser}" = {
        description = "Tezos node service";
        group = "${defaultUser}";
        isSystemUser = true;
      };
    };

    assertions = [
      { assertion = all (node: node.pkgs.stdenv.isLinux) cfg.nodes; message = "Service only defined for Linux systems."; }
    ];
  };
}
