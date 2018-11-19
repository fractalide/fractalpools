(import <nixpkgs> {}).fetchFromGitHub (builtins.fromJSON (builtins.readFile ./default.json))
