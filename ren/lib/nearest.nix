# README.md#predicates `nearest K s` (#57) and `upTo K e` (#58).
ren: {
  # the instance of the nearest ancestor-or-self scope of s matching K (gen-select subkind), or null
  nearestAt =
    ctx: opts: K: s:
    let
      id = s.__scope or (throw "ren: nearest: needs a scope, not an instance");
      n = ren.gen.prelude.findFirst (ren.predicates.test ctx opts K) null ([ id ] ++ ctx.ancestors id);
    in
    if n == null then null else (ctx.data n).instance;
  upTo =
    K: e:
    let
      inherit (ren.predicates) and anyOf has;
    in
    and [
      K
      (anyOf [
        e
        (has e)
      ])
    ];
}
