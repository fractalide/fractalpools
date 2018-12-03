{ callPackage ? pkgs.callPackage
, pkgs ? import (import ./pins/nixpkgs) {}
}:

{
  modules = callPackage ./modules {};
}
