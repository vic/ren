# README.md v35 strata row 3: one static graph of classes and channels. K -> c / K -> K' when K's
# `into` returns channel key c / class key K'; c -> K when c's `into` returns class key K.
stimpy: {
  strata3 =
    {
      classKeys, # class -> [ key its `into` returns ]
      chanClasses, # channel -> [ class ]
      classes,
      channels,
    }:
    let
      inherit (stimpy) lib;
      inherit (lib) attrNames filter;
      label = kind: map (n: "${kind} `${n}`");
      # K's own name forwards strictly up the scope tree (never to itself): not an edge
      out = k: filter (j: j != k) (classKeys k);
      classEdges =
        k:
        label "channel" (filter (j: channels ? ${j}) (out k))
        ++ label "class" (filter (j: classes ? ${j}) (out k));
      edges = builtins.listToAttrs (
        map (k: lib.nameValuePair "class `${k}`" (classEdges k)) (attrNames classes)
        ++ map (c: lib.nameValuePair "channel `${c}`" (label "class" (chanClasses c))) (attrNames channels)
      );
      succ = n: lib.sort lib.lessThan (lib.unique edges.${n});
      # depth-first, successors in order, no node twice: the first simple path u -> … -> u
      walk =
        u: seen: n:
        lib.foldl'
          (
            acc: m:
            if acc.path != null then
              acc
            else if m == u then
              acc // { path = [ n ]; }
            else if acc.seen ? ${m} then
              acc
            else
              let
                r = walk u (acc.seen // { ${m} = true; }) m;
              in
              r // { path = if r.path == null then null else [ n ] ++ r.path; }
          )
          {
            inherit seen;
            path = null;
          }
          (succ n);
      pathOf = u: (walk u { ${u} = true; } u).path;
      cyclic = lib.filter (u: pathOf u != null) (attrNames edges);
      # a cycle starting at a channel ("channel `" < "class `") is printed from the next class
      p = pathOf (builtins.head cyclic);
      q =
        if lib.hasPrefix "channel" (builtins.head p) then builtins.tail p ++ [ (builtins.head p) ] else p;
      shown = q ++ [ (builtins.head q) ];
    in
    cyclic == [ ] || throw "ren: stratum 3 cycle: ${lib.concatStringsSep " -> " shown}";
}
