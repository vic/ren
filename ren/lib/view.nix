# The fleet is a module (fleet.md:134,579): `options.ren` is the surface, `ren` = `_module.args.ren`.
# One key = one file: kinds/classes/channels/aspects are `lazyAttrsOf raw` (a name in two files = error).
# Instances `ren.<kind>.<name>` are deferred modules, evaluated by the kind's gen-schema registry (kinds-check.nix).
ren: {
  view =
    let
      declared = [
        "kinds"
        "classes"
        "channels"
        "aspects"
      ];
    in
    {
      inherit declared;
      module =
        { lib, ... }:
        let
          t = lib.types;
        in
        {
          options.ren = lib.mkOption {
            default = { };
            type = t.submodule {
              freeformType = t.lazyAttrsOf (t.lazyAttrsOf t.deferredModule);
              options = lib.genAttrs declared (
                _:
                lib.mkOption {
                  type = t.lazyAttrsOf t.raw;
                  default = { };
                }
              );
            };
          };
        };
    };
}
