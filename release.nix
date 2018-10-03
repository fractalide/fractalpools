{ isTravis ? false
}:

let
  genJobs = nixpkgs: nixos: let
    pkgs = if nixpkgs == null then null else import nixpkgs {};
    os = import nixos {
      configuration = import ./stub-system/configuration.nix (lib.optionalAttrs (pkgs != null) { inherit pkgs; });
    };
  in
    { inherit (os) system; };
  inherit (import pinnedNixpkgs {}) lib;
  pinnedNixpkgs = import ./pins/nixpkgs;
  pinnedNixos = (import pinnedNixpkgs {}).runCommand "nixos" { inherit pinnedNixpkgs; } ''
    mkdir $out
    ln -s $pinnedNixpkgs $out/nixpkgs
    cat >$out/default.nix <<EOF
      { configuration }: import ./nixpkgs/nixos { inherit configuration; }
    EOF
  '';
in
genJobs null pinnedNixos // {
  unstable = genJobs <nixpkgs> <nixpkgs/nixos>;
  oldstable = genJobs <nixos-oldstable> <nixos-oldstable/nixos>;
  stable = genJobs <nixos-stable> <nixos-stable/nixos>;
  nixos-unstable = genJobs <nixos-unstable> <nixos-unstable/nixos>;
} // (import <nixpkgs> {}).lib.optionalAttrs isTravis {
  travisOrder = [ "system" ];
}
