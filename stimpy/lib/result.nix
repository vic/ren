# evalFleet RESULT (design "evalFleet RESULT"), each field after the checks of its stratum
stimpy: {
  result =
    {
      ren,
      st,
      act,
      content,
      pl,
      col,
      emissions,
    }:
    let
      inherit (stimpy) lib;
      pos = lib.listToAttrs (lib.imap0 (i: id: lib.nameValuePair id i) st.order);
      c0 = lib.all lib.id ren.__ren.checks;
      c2 = c0 && lib.all lib.id content.checks && col.cycle; # a stratum-3 cycle is named before pools
      c3 = c2 && lib.all lib.id col.checks;
      after = ok: lib.mapAttrs (_: builtins.seq ok);
      emitted = lib.mapAttrs (_: es: lib.unique (map (e: e.id) es)) emissions;
      edge = class: from: to: { inherit class from to; };
      edgeKey = e: [
        pos.${e.from}
        e.class
        pos.${e.to}
      ];
    in
    after c0 {
      inherit (st) scopes;
      inherit (act) active;
    }
    // after c2 {
      inherit (content) landed;
      inherit (pl) pools;
      inherit emitted;
      branches = lib.mapAttrs (_: lib.filterAttrs (_: i: i != null)) content.branches;
      # channel -> { emitters = [ id ]; receivers = emitter id -> [ id ]; } (diagram data, #48)
      channels = lib.mapAttrs (c: es: {
        emitters = es;
        receivers = lib.genAttrs es (id: pl.recv c { inherit id; });
      }) emitted;
    }
    // after c3 {
      inherit (col) outputs;
      forwarded = lib.mapAttrs (
        j: _: lib.mapAttrs (_: map (f: f.from)) (lib.groupBy (f: f.t) (lib.filter (f: f.j == j) col.fwds))
      ) ren.classes;
      # [ { class; from; to; } ]: class forwards and channel `into` forwards, by scope order of from/to
      forwards = lib.sort (a: b: lib.lessThan (edgeKey a) (edgeKey b)) (
        lib.unique (map (f: edge f.j f.from f.t) col.fwds ++ map (f: edge f.k f.from f.t) col.chanFwds)
      );
    };
}
