# Facter: a metal host loads its hardware report when ./facter/<host>.json exists.
{ ren, metal, ... }:
{
  ren.aspects.facter = {
    at = metal;
    nixos =
      { host, lib, ... }:
      let
        report = ./facter/${host.name}.json;
      in
      lib.optionalAttrs (builtins.pathExists report) { hardware.facter.reportPath = report; };
  };
}
