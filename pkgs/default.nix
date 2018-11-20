{ pkgs ? import (import ../pins/nixpkgs) {}
, lib ? pkgs.lib
, newScope ? pkgs.newScope
}:

lib.makeScope newScope (self: with self; {
  backerei-src = import ../pins/backerei;
  inherit (callPackage (backerei-src + /release.nix) {}) backerei;
})
