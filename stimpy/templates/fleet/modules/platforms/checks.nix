# Checks: class checks at each system; each content key is one nixosTest at `checks.<sys>.<name>`.
# `drvs.<name>` is a ready check derivation (for example forwarded by an `into` that reads `outputs`, #60).
{
  ren,
  lib,
  inputs,
  ...
}:
{
  ren.classes.checks = {
    at = ren.kinds.system;
    into =
      { system, ... }:
      ms:
      let
        tests =
          (lib.evalModules {
            modules = ms ++ [
              {
                freeformType = lib.types.attrsOf lib.types.deferredModule;
                options.drvs = lib.mkOption {
                  type = lib.types.lazyAttrsOf lib.types.raw;
                  default = { };
                };
              }
            ];
          }).config;
      in
      {
        checks.${system.name} =
          builtins.mapAttrs (
            name: t:
            inputs.nixpkgs.legacyPackages.${system.name}.testers.runNixOSTest {
              imports = [ t ];
              inherit name;
            }
          ) (removeAttrs tests [ "drvs" ])
          // tests.drvs;
      };
  };
}
