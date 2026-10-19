# #32: class checks writes checks.<sys>.<name>; buildHost in the deployment record; facter at metal.
{ lib, r, ... }:
let
  i = import ./_ids.nix;
  names = builtins.attrNames;
in
{
  # row: one named check on x86_64-linux; other systems get none (key names only: no pkgs here)
  test-checks-names = {
    expr = lib.mapAttrs (_: names) r.outputs.checks;
    expected = {
      x86_64-linux = [ "web" ];
      aarch64-linux = [ ];
      aarch64-darwin = [ ];
    };
  };
  # row: buildHost is data on the machine, read by the deployment record (null = deployer builds)
  test-buildhost = {
    expr = lib.mapAttrs (_: d: d.buildHost) r.pools.deployment;
    expected = {
      ${i.lb} = null;
      ${i.web1} = null;
      ${i.web2} = "10.0.1.1";
      ${i.stage} = null;
    };
  };
  # row: facter active on metal hosts only (the report itself is e2e)
  test-facter-metal = {
    expr = lib.sort lib.lessThan r.active.facter;
    expected = lib.sort lib.lessThan i.metals;
  };
}
