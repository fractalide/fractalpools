{ pkgs ? import (import ../pins/nixpkgs) {}
, lib ? pkgs.lib
, newScope ? pkgs.newScope
}:

lib.makeScope newScope (self: with self; {
  backerei = (import (import ../pins/backerei) {});
})
