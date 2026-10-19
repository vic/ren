# The fleet is a module (fleet.md:134,579): `options.ren` is the surface, `ren` = `_module.args.ren`.
# classes/channels: one key = one file (`lazyAttrsOf raw`); kinds merge (decl-types.nix); `ren.aspects` = gen-aspects `aspectsType` (merges).
# Instances `ren.<kind>.<name>` are deferred modules, evaluated by the kind's gen-schema registry (kinds-check.nix).
ren: {
  view =
    let
      inherit (ren) gen;
      inherit (gen.prelude) imap0 filterAttrs;
      t = ren.genLib.types;
      facet = type: default: {
        category = "facet";
        option = ren.genLib.mkOption { inherit type default; };
      };
      cat = category: builtins.mapAttrs (_: _: { inherit category; });
      cnf = decl: {
        keySemantics =
          cat "class" decl.classes
          // cat "channel" decl.channels
          // {
            at = facet t.raw null;
            excludes = facet (t.listOf t.raw) [ ];
            __ren = facet t.raw "aspect";
          };
        aspectModules = [ (ren.declTypes.bareClass decl.classes) ];
      };
      declared = [
        "kinds"
        "classes"
        "channels"
      ];
    in
    {
      declared = declared ++ [ "aspects" ];
      # Ren's aspect records; an `includes` element must be a ref (inline aspects refused: #21, #35)
      aspects =
        decl:
        let
          isRef = b: (decl.aspects.${b.name}.key or null) == b.key;
          # authored keys: a class with content or a non-null channel (unset reads `null`)
          authored =
            name: e: k: _:
            let
              c = gen.aspects.keyCategory (cnf decl) k;
            in
            if c == null then
              throw "ren: aspect `${name}`: key `${k}` is neither class nor channel"
            else
              c == "class" && gen.aspects.hasClassContent e.${k} || c == "channel" && e.${k} != null;
          norm =
            name: e:
            e
            // {
              inherit name;
              includes = imap0 (
                i: b:
                if isRef b then
                  b
                else
                  throw "ren: aspect `${name}`: includes[${toString i}] is not a ref to a declared aspect (inline aspects are not supported, see #21)"
              ) e.includes;
              content = if e.meta.bare then ren.content.bare else filterAttrs (authored name e) e;
            };
        in
        builtins.mapAttrs norm decl.aspects;
      module =
        { lib, ... }:
        let
          opt = type: (facet type { }).option;
        in
        {
          options.ren = opt (
            t.submodule (
              { config, ... }:
              {
                freeformType = t.lazyAttrsOf (t.lazyAttrsOf t.deferredModule);
                options = lib.genAttrs declared (_: opt (t.lazyAttrsOf t.raw)) // {
                  kinds = opt (t.lazyAttrsOf ren.declTypes.kind);
                  aspects = opt (gen.aspects.aspectsType (cnf config));
                };
              }
            )
          );
        };
    };
}
