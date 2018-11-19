{ pkgs ? import (import ../pins/nixpkgs) {}
, newScope ? pkgs.newScope
}:

let inherit (pkgs) lib; in

lib.fix' (self: {
  callPackage = newScope self;
  backerei-src = import ../pins/backerei;
  inherit (self.callPackage (self.backerei-src + /release.nix) {}) backerei;
})
