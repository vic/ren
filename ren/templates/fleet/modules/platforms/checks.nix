# Checks: class nixosTest at each system; each content key is one nixosTest at `checks.<sys>.<name>`.
{
  ren,
  lib,
  inputs,
  ...
}:
{
  ren.classes.nixosTest = {
    at = ren.kinds.system;
    into =
      { system, ... }:
      ms:
      let
        tests =
          (lib.evalModules {
            modules = ms ++ [ { freeformType = lib.types.attrsOf lib.types.deferredModule; } ];
          }).config;
      in
      {
        checks.${system.name} = builtins.mapAttrs (
          name: t:
          inputs.nixpkgs.legacyPackages.${system.name}.testers.runNixOSTest {
            imports = [ t ];
            inherit name;
          }
        ) tests;
      };
  };
}
