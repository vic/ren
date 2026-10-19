{
  inputs.gen.url = "github:sini/gen/bcbc5ca579614643fa3433034fd0248b0d551f65";
  inputs.gen.inputs.nixpkgs.follows = "";

  outputs =
    inputs:
    let
      lib = import ./default.nix { gen = import inputs.gen.outPath { }; };
    in
    {
      inherit lib;
      flakeModules.default = lib.flakeModule;
      templates.fleet = {
        path = ./templates/fleet;
        description = "Ren fleet";
      };
    };
}
