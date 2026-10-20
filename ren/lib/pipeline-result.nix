# evalFleet RESULT (the shared template's tier-1 API): plain, lazy data over the pipeline stages.
# ids are scope ids "kind:name/..."; id lists are in scope-path (preorder) order.
ren: {
  pipelineResult =
    {
      lib,
      sc,
      act,
      aspects,
      classes,
      branchIx,
      receivers,
      o,
      ...
    }:
    let
      inherit (builtins)
        attrNames
        concatMap
        filter
        groupBy
        lessThan
        listToAttrs
        mapAttrs
        seq
        sort
        ;
      pos = listToAttrs (lib.imap0 (i: id: lib.nameValuePair id i) sc.order);
      inOrder = ids: sort (a: b: pos.${a} < pos.${b}) (lib.unique ids);
      byScope = f: ids: lib.genAttrs ids f;
      edge = class: from: to: { inherit class from to; };
      edgeKey = e: [
        pos.${e.from}
        e.class
        pos.${e.to}
      ];
      # landing errors (unknown key, key landing nowhere) come before landing-derived data,
      # then the stratum-3 cycle check (so reading only `pools` names a cycle too)
      checked = f: mapAttrs (_: v: seq (builtins.deepSeq o.landed null) (seq o.cycle v)) f;
    in
    {
      inherit (o) outputs;
      inherit (sc) scopes;
      # class -> target scope -> [ forwarding scope ]
      forwarded = mapAttrs (
        k: _:
        mapAttrs (_: map (r: r.id)) (
          groupBy (r: o.collect.target r.c r.id k) (filter (r: r.k == k) o.collect.fwd)
        )
      ) classes;
      active = mapAttrs (n: _: filter (act.active n) sc.order) aspects;
    }
    // checked {
      # class -> scope -> [ aspect ] (aspect attrNames order)
      landed = mapAttrs (
        c: _:
        mapAttrs (_: map (l: l.n)) (
          groupBy (l: l.id) (
            concatMap (n: map (id: { inherit n id; }) (o.landed.${n}.${c} or [ ])) (attrNames aspects)
          )
        )
      ) classes;
      emitted = mapAttrs (_: es: inOrder (map (e: e.path) es)) o.emissions;
      # channel -> { emitters = [ id ]; receivers = emitter id -> [ id ]; } (diagram data, #48)
      channels = mapAttrs (c: es: {
        emitters = inOrder (map (e: e.path) es);
        receivers = byScope (id: receivers c { path = id; }) (map (e: e.path) es);
      }) o.emissions;
      # [ { class; from; to; } ]: class forwards and channel `into` forwards, by scope order of from/to
      forwards = sort (a: b: lessThan (edgeKey a) (edgeKey b)) (
        lib.unique (
          map (r: edge r.k r.id (o.collect.target r.c r.id r.k)) o.collect.fwd
          ++ map (f: edge f.k f.from f.t) o.chan.fwds
        )
      );
      pools = mapAttrs (c: es: byScope o.pools.${c} (inOrder (concatMap (receivers c) es))) o.emissions;
      branches = mapAttrs (
        c: _: lib.filterAttrs (_: i: i != null) (byScope (branchIx c) sc.order)
      ) classes;
    };
}
