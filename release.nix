{ isTravis ? false
}:

let
  genJobs = nixpkgs: nixos: let
    pkgs = import nixpkgs {};
    os = import nixos { configuration = import ./stub-system/configuration.nix { inherit pkgs; }; };
  in
    { inherit (os) system; };
  pinnedNixpkgs = import ./pins/nixpkgs;
  pinnedNixos = (import pinnedNixpkgs {}).runCommand "nixos" { inherit pinnedNixpkgs; } ''
    mkdir $out
    ln -s $pinnedNixpkgs $out/nixpkgs
    cat >$out/default.nix <<EOF
      { configuration }: import ./nixpkgs/nixos { inherit configuration; }
    EOF
  '';
in
genJobs pinnedNixpkgs pinnedNixos // {
  unstable = genJobs <nixpkgs> <nixpkgs/nixos>;
  oldstable = genJobs <nixos-oldstable> <nixos-oldstable/nixos>;
  stable = genJobs <nixos-stable> <nixos-stable/nixos>;
} // (import <nixpkgs> {}).lib.optionalAttrs isTravis {
  travisOrder = [ "system" ];
}
