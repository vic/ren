# stratum 0 (README.md#vocabulary, README.md#features; README.md#kinds README.md#scopes): below/spawns tree of scopes
stimpy: {
  scopes =
    {
      ren,
      rawKinds,
      ctx,
    }:
    let
      inherit (stimpy) lib pred;
      inherit (lib) attrNames concatMap elem;
      inherit (stimpy.kindgraph { inherit ren rawKinds; })
        fnArgs
        body
        below
        kindsOf
        ok
        roots
        ;
      mk =
        parent: K: n: inst:
        let
          up = if parent == null then { } else parent.__ren;
          path = (up.path or [ ]) ++ [
            {
              kind = K;
              name = n;
            }
          ];
          me = inst // {
            __ren = inst.__ren // {
              scope = self;
            };
          };
          self =
            removeAttrs (if parent == null then { } else parent) [ "__ren" ]
            // lib.mapAttrs (a: _: inst.${a}) (fnArgs K)
            // lib.genAttrs (kindsOf K) (_: me) # README.md#scopes nearest wins
            // lib.optionalAttrs (parent != null) { parent = up.inst; }
            // {
              __ren = {
                ref = "scope";
                kind = K;
                kinds = kindsOf K;
                id = lib.concatMapStringsSep "/" (p: "${p.kind}:${p.name}") path;
                ancestors = if parent == null then [ ] else [ up.id ] ++ up.ancestors;
                instIds = (up.instIds or [ ]) ++ [ inst.__ren.id ];
                inst = me;
                inherit path;
              };
            };
        in
        self;
      child =
        s: C: got: n:
        let
          i = got.${n};
          c = mk s C n i;
          g = ren.__ren.guard C;
        in
        if (i.__ren.kind or null) != C then
          throw "ren: spawns.${C} at ${s.__ren.id}: ${n} is not exactly a ${C}"
        else if elem i.__ren.id s.__ren.instIds then
          throw "ren: instance ${lib.replaceStrings [ "/" ] [ ":" ] i.__ren.id} twice on path ${c.__ren.id}" # README.md#kinds
        else if g == null || pred.match ctx g c then
          [ c ]
        else
          [ ];
      kids =
        s:
        concatMap (
          C:
          let
            got = ((body s.__ren.kind).spawns.${C} or (_: ren.${C})) s;
          in
          concatMap (child s C got) (attrNames got)
        ) (below s.__ren.kind);
      walk =
        s:
        let
          ks = kids s;
        in
        [
          {
            scope = s;
            kids = map (c: c.__ren.id) ks;
          }
        ]
        ++ concatMap walk ks;
      rootScopes = concatMap (R: map (n: mk null R n ren.${R}.${n}) (attrNames ren.${R})) roots;
      all = concatMap walk rootScopes;
      byId = f: lib.listToAttrs (map (x: lib.nameValuePair x.scope.__ren.id (f x)) all);
    in
    builtins.seq ok {
      order = map (x: x.scope.__ren.id) all;
      scopes = byId (x: x.scope);
      children = byId (x: x.kids);
      ancestors = byId (x: x.scope.__ren.ancestors);
    };
}
