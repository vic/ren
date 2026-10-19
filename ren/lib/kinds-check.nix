# instances for kinds.nix: one gen-schema registry per kind (fields, strictness, guard, id_hash),
# plus Ren glue: name uniqueness per is-root family, and the instance mark predicates read.
ren: {
  kindsCheck =
    { rootOf, ... }:
    {
      mkInstances =
        {
          lib,
          kinds,
          decls,
        }:
        let
          registries =
            (lib.evalModules {
              modules = [
                {
                  options = builtins.mapAttrs (_: k: ren.gen.schema.mkInstanceRegistry { } k.schema) kinds;
                  # function module: a merged deferredModule (`{ imports; }`) is not read as config shorthand
                  config = builtins.mapAttrs (
                    _:
                    builtins.mapAttrs (
                      _: m: _:
                      m
                    )
                  ) decls;
                }
              ];
            }).config;
          mkOne =
            k: n: entry:
            let
              clash = builtins.filter (
                k2: k2 != k && decls.${k2} ? ${n} && rootOf kinds k2 lib == rootOf kinds k lib
              ) (builtins.attrNames decls);
            in
            # scope ids are "kind:name/kind:name" (scopes-parent.nix parses them): a name with `/` or `:` cannot exist.
            if builtins.match ".*[/:].*" n != null then
              throw "ren: instance name `${n}` (kind `${k}`) must not contain `/` or `:`"
            else if clash != [ ] then
              throw "ren: name `${n}` used by both kind `${k}` and kind `${builtins.head clash}`"
            else
              entry
              // {
                __ren = "instance";
                kind = k;
                __id = "${rootOf kinds k lib}:${n}";
              };
        in
        builtins.mapAttrs (k: builtins.mapAttrs (mkOne k)) (builtins.intersectAttrs decls registries);
    };
}
