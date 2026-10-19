# #20: class content gets the `lib` of the class it lands in (home-manager's `lib.hm`), not Ren's.
{ inputs }:
let
  probe =
    { ren, ... }:
    {
      ren.aspects.class-lib = {
        at = ren.kinds.user;
        homeManager =
          { lib, ... }:
          {
            home.activation.ren-probe = lib.hm.dag.entryAfter [ "writeBoundary" ] "true";
          };
      };
    };
  o = inputs.impl.lib.mkFlake inputs {
    imports = [
      (inputs.import-tree ../modules)
      probe
    ];
  };
in
{
  test-class-content-sees-class-lib = {
    expr = o.homeConfigurations.alice-laptop.config.home.activation.ren-probe.after;
    expected = [ "writeBoundary" ];
  };
}
