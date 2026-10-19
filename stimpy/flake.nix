{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  outputs =
    { nixpkgs, ... }:
    let
      fleet = {
        path = ./templates/fleet;
        description = "Ren fleet demo";
      };
      lib = import ./default.nix { inherit (nixpkgs) lib; };
    in
    {
      inherit lib;
      flakeModules.default = lib.flakeModule;
      templates = {
        inherit fleet;
        default = fleet;
      };
    };
}
