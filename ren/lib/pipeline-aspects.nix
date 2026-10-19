# aspects: normalise declared aspects; non-meta keys are content.
# An inline aspect in `includes` is an aspect too, named by its `name` or `<taker>/<index>` (fleet.md:511,576).
ren: {
  pipelineAspects =
    decl:
    let
      meta = [
        "name"
        "at"
        "includes"
        "excludes"
      ];
      isRef = b: (b.__ren or null) == "aspect";
      norm =
        name: a:
        let
          items = ren.gen.prelude.imap0 (
            i: b: if isRef b then { ref = b; } else { inl = norm (b.name or "${name}/${toString i}") b; }
          ) (a.includes or [ ]);
        in
        {
          __ren = "aspect";
          inherit name;
          at = a.at or null;
          includes = map (x: x.ref or x.inl) items;
          excludes = a.excludes or [ ];
          content = removeAttrs a meta;
          inlines = builtins.concatMap (x: if x ? inl then [ x.inl ] ++ x.inl.inlines else [ ]) items;
        };
      # refs (`ren.aspects.x`) read `declared`: its keys never force an `includes` element
      declared = builtins.mapAttrs norm (decl.aspects or { });
      inlines = map (
        a:
        if declared ? ${a.name} then
          throw "ren: inline aspect `${a.name}` in `includes` has the name of a declared aspect"
        else
          a
      ) (builtins.concatMap (a: a.inlines) (builtins.attrValues declared));
    in
    {
      inherit declared;
      all =
        declared
        // builtins.listToAttrs (
          map (value: {
            inherit (value) name;
            inherit value;
          }) inlines
        );
    };
}
