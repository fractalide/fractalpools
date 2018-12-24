{ config, lib, ... }:

let pkgs_ = import (import ../pins/nixpkgs) {}; in

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
    bakerAddressAlias = mkOption {
      default = "baker";
      type = types.str;
      description = "The alias of the implicit address used by the baker.";
    };
    bakerDir = mkOption {
      type = types.str;
      description = "Where to store baker state.";
    };
    bakerFee = mkOption {
      default = 15;
      type = types.int;
      description = "Baker's fee, in percent";
    };
    bakerPaymentsFrom = mkOption {
      type = types.str;
      description = "The hash of the account paying rewards to stakers";
    };
    bakerPaymentsFromName = mkOption {
      type = types.str;
      description = "The human-readable name of the account paying rewards to stakers";
    };
    bakerStatsExportDir = mkOption {
      type = types.str;
      description = "Where to store exported baker stats.";
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
    inherit (tezos-baking-platform.tezos."${current.network}") kit;
    tzscanUrl = tzscanUrls."${current.network}";
    monitorBootstrapped = callPackage ./monitor-bootstrapped.sh.nix {
      inherit kit index;
      inherit (current) bakerDir;
    };
    inherit (current.pkgs.callPackage ../pkgs {}) callPackage;
    tezos-baking-platform = callPackage (import ../pins/tezos-baking-platform) {};
    init-name = "tezos-${current.network}-init-${toString index}";
    init-value = {
      description = "Tezos ${current.network} initialization";
      script = callPackage ./tezos-init.sh.nix {
        inherit kit;
        inherit (current) bakerAddressAlias bakerDir bakerStatsExportDir configDir user;
        baking = current.baking.enable;
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
      script = callPackage ./tezos-run.sh.nix {
        inherit (current) configDir;
        inherit index kit tzscanUrl;
      };
      wantedBy = [ "multi-user.target" ];
      after = [ "${init-name}.service" ];
      wants = [ "${init-name}.service" ];
      serviceConfig = {
        Restart = "always";
        User = current.user;
      };
    };
    accuser-name = "tezos-${current.network}-accuser-${toString index}";
    accuser-value = {
      description = "Tezos ${current.network} accuser";
      script = callPackage ./tezos-accuser.sh.nix {
        inherit index kit;
        inherit (current) bakerDir;
      };
      wantedBy = [ "multi-user.target" ];
      after = [ "${run-name}.service" ];
      wants = [ "${run-name}.service" ];
      serviceConfig = {
        ExecStartPre = monitorBootstrapped;
        Restart = "always";
        User = current.user;
      };
    };
    baker-name = "tezos-${current.network}-baker-${toString index}";
    baker-value = {
      description = "Tezos ${current.network} baker";
      script = callPackage ./tezos-baker.sh.nix {
        inherit index kit;
        inherit (current) bakerAddressAlias bakerDir configDir;
      };
      wantedBy = [ "multi-user.target" ];
      after = [ "${run-name}.service" ];
      wants = [ "${run-name}.service" ];
      serviceConfig = {
        ExecStartPre = monitorBootstrapped;
        Restart = "always";
        User = current.user;
      };
    };
    endorser-name = "tezos-${current.network}-endorser-${toString index}";
    endorser-value = {
      description = "Tezos ${current.network} endorser";
      script = callPackage ./tezos-endorser.sh.nix {
        inherit index kit;
        inherit (current) bakerAddressAlias bakerDir;
      };
      wantedBy = [ "multi-user.target" ];
      after = [ "${run-name}.service" ];
      wants = [ "${run-name}.service" ];
      serviceConfig = {
        ExecStartPre = monitorBootstrapped;
        Restart = "always";
        User = current.user;
      };
    };
    stats-name = "tezos-${current.network}-baker-stats-${toString index}";
    stats-script = callPackage ./tezos-baker-stats.sh.nix {
      inherit index kit;
      inherit (current) bakerDir;
    };
    stats-value = {
      description = "Tezos ${current.network} baker stats export";
      script = ''
        exec ${stats-script} "${current.bakerStatsExportDir}" "${current.bakerAddressAlias}" ${toString current.bakerFee} \
          --from ${current.bakerPaymentsFrom} --from-name ${current.bakerPaymentsFromName}
      '';
      serviceConfig = {
        ExecStartPre = monitorBootstrapped;
        User = current.user;
      };
      startAt = "*:07";
    };
  in
    makeServiceEntries (index + 1) (builtins.tail nodes) (done // {
      "${init-name}" = init-value;
      "${run-name}" = run-value;
    } // lib.optionalAttrs current.baking.enable {
      "${accuser-name}" = accuser-value;
      "${baker-name}" = baker-value;
      "${endorser-name}" = endorser-value;
      "${stats-name}" = stats-value;
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
      { assertion = all (node: node.pkgs.stdenv.isLinux) cfg.nodes; message = "Services defined only for Linux systems."; }
    ];
  };
}
