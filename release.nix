{ isTravis ? false
}:

let
  genJobs = nixpkgsPath: let pkgs = import nixpkgsPath {}; in {
    inherit (import "${nixpkgsPath}/nixos" {
      configuration = import ./stub-system/configuration.nix { inherit pkgs; };}) system;
  };
in
genJobs (import ./pins/nixpkgs) // {
  unstable = genJobs <nixpkgs>;
  oldstable = genJobs <nixos-oldstable>;
  stable = genJobs <nixos-stable>;
} // (import <nixpkgs> {}).lib.optionalAttrs isTravis {
  travisOrder = [ "system" ];
}
