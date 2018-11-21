{ pkgs ? import (import ../pins/nixpkgs) {}
, lib ? pkgs.lib
, newScope ? pkgs.newScope
}:

lib.makeScope newScope (self: with self; {
  backerei-src = import ../pins/backerei;
  inherit (callPackage (backerei-src + /release.nix) {
    compiler = if pkgs.haskell.packages ? ghc844 then pkgs.haskell.packages.ghc844
      else pkgs.haskell.packages.ghc843;
  }) backerei;
})
