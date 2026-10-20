# stratum 1 (README.md#kinds, README.md#channels, README.md#features): aspect activation, stratified
stimpy: {
  activation =
    {
      aspects,
      st, # stratum 0 result
      ctx, # pred ctx; activeAt replaced here
    }:
    let
      inherit (stimpy) lib pred;
      inherit (lib)
        attrNames
        concatMap
        elem
        filter
        ;
      names = attrNames aspects;
      refNames = xs: map (x: x.__ren.name) xs;
      by = key: a: filter (b: elem a (refNames (aspects.${b}.${key} or [ ]))) names;
      includers = lib.genAttrs names (by "includes");
      excluders = lib.genAttrs names (by "excludes");
      deps = lib.genAttrs names (
        a:
        pred.refsOf (aspects.${a}.at or { })
        ++ map (b: {
          aspect = b;
          positive = true;
        }) includers.${a}
        ++ map (b: {
          aspect = b;
          positive = false;
        }) excluders.${a}
      );
      reach = lib.genAttrs names (
        a:
        map (x: x.key) (
          lib.genericClosure {
            startSet = map (d: { key = d.aspect; }) deps.${a};
            operator = x: map (d: { key = d.aspect; }) deps.${x.key};
          }
        )
      );
      scc = a: [ a ] ++ filter (b: b != a && elem b reach.${a} && elem a reach.${b}) names;
      # README.md#channels a negative cycle is an error
      negCycle = lib.unique (
        concatMap (
          a: concatMap (d: lib.optional (!d.positive && elem a reach.${d.aspect}) a) deps.${a}
        ) names
      );
      ids = st.order;
      selfAndUp = id: [ id ] ++ st.ancestors.${id};
      step =
        members: lookup:
        lib.genAttrs members (
          a:
          let
            c = ctx // {
              activeAt = b: s: lookup b s.__ren.id;
            };
            hit = bs: id: lib.any (u: lib.any (b: lookup b u) bs) (selfAndUp id);
          in
          lib.genAttrs ids (
            id:
            ((aspects.${a} ? at && pred.match c aspects.${a}.at st.scopes.${id}) || hit includers.${a} id)
            && !(hit excluders.${a} id)
          )
        );
      # least fixpoint per SCC; outside refs read the (acyclic) global table
      fix =
        members:
        let
          go =
            cur:
            let
              nxt = step members (b: id: if cur ? ${b} then cur.${b}.${id} else table.${b}.${id});
            in
            if nxt == cur then cur else go nxt;
        in
        go (lib.genAttrs members (_: lib.genAttrs ids (_: false)));
      reps = lib.genAttrs names (a: lib.head (lib.sort lib.lessThan (scc a)));
      solved = lib.genAttrs (lib.unique (lib.attrValues reps)) (r: fix (scc r));
      table =
        if negCycle != [ ] then
          throw "ren: not stratified: ${toString negCycle}"
        else
          lib.mapAttrs (a: r: solved.${r}.${a}) reps;
    in
    {
      active = lib.mapAttrs (_: t: filter (id: t.${id}) ids) table;
      activeAt =
        a: s: table.${a}.${s.__ren.id} or (throw "ren: unknown aspect ${a} or scope ${s.__ren.id or "?"}");
    };
}
