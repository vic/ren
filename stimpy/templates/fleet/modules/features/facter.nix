# Facter: a metal host loads its hardware report when ./facter/<host>.json exists.
{ ren, ... }:
{
  ren.aspects.facter = {
    at = ren.helpers.metal;
    nixos =
      { host, lib, ... }:
      let
        report = ./facter/${host.name}.json;
      in
      lib.optionalAttrs (builtins.pathExists report) { hardware.facter.reportPath = report; };
  };
}
