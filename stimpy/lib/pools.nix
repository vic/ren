# pools (README.md#kinds): pool(c, r) = fold_c [ v(e) | e emits c, r matches `to e` ], path order
stimpy: {
  pools =
    {
      channels,
      st,
      ctx,
      emissions, # channel -> [ { id; v; } ] in scope-path order
    }:
    let
      inherit (stimpy) lib pred;
      inherit (lib) filter elem;
      # receivers per (channel, emitter scope), shared by that scope's emissions
      recvT = lib.mapAttrs (
        c: ch:
        lib.genAttrs st.order (e: filter (r: pred.match ctx (ch.to st.scopes.${e}) st.scopes.${r}) st.order)
      ) channels;
      recv = c: e: recvT.${c}.${e.id};
      tagged = lib.mapAttrs (
        c: map (e: stimpy.typedEmission c channels.${c} e // { rs = recv c e; })
      ) emissions;
      poolAt = c: r: channels.${c}.fold.fold [ c r ] (map (e: e.v) (filter (e: elem r e.rs) tagged.${c}));
    in
    {
      pools = lib.mapAttrs (
        c: es: lib.genAttrs (lib.unique (lib.concatMap (e: e.rs) es)) (poolAt c)
      ) tagged;
      poolsAt = id: lib.mapAttrs (c: _: poolAt c id) channels;
      inherit recv;
    };
}
