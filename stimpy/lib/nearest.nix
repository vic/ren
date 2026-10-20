# README.md#predicates `nearest K s` (#57) and `upTo K e` (#58); `scoped ctx` = the ctx-bound `is`, `nearest`.
stimpy: {
  scoped = ctx: {
    is = stimpy.pred.is ctx;
    # the instance of the nearest ancestor-or-self scope of s matching K (kinds follow `is`), or null
    nearest =
      K: s:
      let
        path =
          if s.__ren.ref or null == "scope" then
            [ s ] ++ ctx.ancestors s
          else
            throw "ren: nearest: needs a scope, not an instance";
        n = stimpy.lib.findFirst (stimpy.pred.match ctx K) null path;
      in
      if n == null then null else n.__ren.inst;
  };
  upTo =
    K: e:
    let
      inherit (stimpy.pred) and anyOf has;
    in
    and [
      K
      (anyOf [
        e
        (has e)
      ])
    ];
}
