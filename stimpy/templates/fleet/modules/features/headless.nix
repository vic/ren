# Headless: a check reads a host's REALIZED nixos config through `outputs` (stratum 3, #60).
# Content stays data (host name -> forbidden package names); only the class `into` reads `outputs`.
# noGui forwards into `checks` (same system scope) and reads `nixosConfigurations`, which it does not forward into.
{
  ren,
  lib,
  inputs,
  ...
}:
{
  ren.classes.noGui = {
    at = ren.kinds.system;
    into =
      { system, outputs, ... }:
      ms:
      let
        pkgs = inputs.nixpkgs.legacyPackages.${system.name};
        forbid =
          (lib.evalModules {
            modules = ms ++ [ { freeformType = lib.types.attrsOf (lib.types.listOf lib.types.str); } ];
          }).config;
        nameOf = p: p.pname or (builtins.parseDrvName p.name).name;
        check =
          h:
          let
            have = map nameOf outputs.nixosConfigurations.${h}.config.environment.systemPackages;
            bad = builtins.filter (n: builtins.elem n have) forbid.${h};
          in
          pkgs.runCommand "${h}-no-gui" { } (
            if bad == [ ] then "touch $out" else "echo 'gui packages on ${h}: ${toString bad}'; exit 1"
          );
      in
      {
        checks.drvs = lib.listToAttrs (
          map (h: lib.nameValuePair "${h}-no-gui" (check h)) (builtins.attrNames forbid)
        );
      };
  };

  ren.aspects.headless = {
    at = ren.system.x86_64-linux;
    noGui.lb = [ "firefox" ];
  };
}
