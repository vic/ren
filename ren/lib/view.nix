# The fleet is a module (fleet.md:134,579): `options.ren` is the surface, `ren` = `_module.args.ren`.
# classes/channels: one key = one file (`lazyAttrsOf raw`); kinds merge (decl-types.nix); `ren.aspects` = gen-aspects `aspectsType` (merges).
# Instances `ren.<kind>.<name>` are deferred modules, evaluated by the kind's gen-schema registry (kinds-check.nix).
ren: {
  view =
    let
      inherit (ren) gen;
      inherit (gen.prelude) imap0 filterAttrs nameValuePair;
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
        # an authored `name` outranks the type's default name (priority 1500)
        aspectModules = [
          ({ options, ... }: { meta.named = options.name.highestPrio < 1500; })
          (ren.declTypes.bareClass decl.classes)
        ];
      };
      declared = [
        "kinds"
        "classes"
        "channels"
      ];
    in
    {
      declared = declared ++ [ "aspects" ];
      # Ren's aspect records; an inline in `includes` is named by its `name` or `<taker>/<index>` (fleet.md:511,576)
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
                i: b: if isRef b then b else norm (if b.meta.named then b.name else "${name}/${toString i}") b
              ) e.includes;
              content = if e.meta.bare then ren.content.bare else filterAttrs (authored name e) e;
            };
          below = a: builtins.concatMap (b: [ b ] ++ below b) (builtins.filter (b: !isRef b) a.includes);
          top = builtins.mapAttrs norm decl.aspects;
          named =
            a:
            if top ? ${a.name} then
              throw "ren: inline aspect `${a.name}` in `includes` has the name of a declared aspect"
            else
              nameValuePair a.name a;
        in
        top // builtins.listToAttrs (map named (builtins.concatMap below (builtins.attrValues top)));
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
