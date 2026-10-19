# pipeline tail: emissions -> pools -> class collect -> channel `into` -> merged outputs.
ren: {
  pipelineOut =
    {
      lib,
      L,
      C,
      sc,
      test,
      channels,
      classes,
      branchAt,
      renArgs,
      act,
      aspects,
      strata,
      receivers,
    }:
    let
      inherit (builtins) attrNames concatMap filter;
      content = n: k: aspects.${n}.content.${k};
      keyKind =
        k:
        if classes ? ${k} then
          "class"
        else if channels ? ${k} then
          "channel"
        else
          null;
      # ruling: aspect active nowhere has no scopes to land in, so it is not a landing error (fleet-ren.md:108)
      # ruling: an unknown key is an error for every aspect (fleet-ren.md:107); `a.content` refuses it (view.nix)
      landed = lib.mapAttrs (
        n: a:
        let
          ids = filter (act.active n) sc.order;
        in
        if ids == [ ] then
          lib.mapAttrs (_: _: [ ]) a.content
        else
          C.landing {
            inherit keyKind;
            classMatches = k: id: branchAt k id != null;
            channelMatches = k: id: channels.${k} ? at == false || test channels.${k}.at id;
          } a ids
      ) aspects;
      # [ { aspect name; id; value } ] for key k
      at = k: concatMap (n: map (id: { inherit n id; }) (landed.${n}.${k} or [ ])) (attrNames aspects);
      collect = L.mkCollect {
        inherit classes branchAt;
        channelNames = attrNames channels;
        scopeOrder = lib.reverseList sc.order;
        inherit (sc) ancestors;
        renArgsAt = renArgs;
        argsFor = c: id: { outputs = strata.outputsFor outputs c id; };
        contentModules =
          c: id: map (l: C.asModule (renArgs id) (content l.n c)) (filter (l: l.id == id) (at c));
      };
      # ruling: channel `at` is the emitter scopes, also for emissions from a class `into` (fleet-ren.md:26,102)
      outside =
        c: e:
        if channels.${c} ? at && !test channels.${c}.at e.path then
          throw "ren: class `${e.class}` at ${e.path} emits channel `${c}` outside its `at`"
        else
          e;
      emissions = lib.mapAttrs (
        c: _:
        map (l: {
          path = l.id;
          value = C.callContent (renArgs l.id) (content l.n c);
        }) (at c)
        ++ map (e: { inherit (e) path value; }) (
          map (outside c) (filter (e: e.channel == c) collect.emissions)
        )
      ) channels;
      pools = C.mkPools { inherit channels emissions receivers; } sc.order;
      # ruling: a channel `into` result is top-level outputs only in v1; class/channel keys are refused (fleet-ren.md:100)
      chanFrag =
        c: r:
        let
          res = channels.${c}.into (renArgs r) (pools.${c} r);
          # ruling: the channel's own name is its top-level output (`packages` into -> `packages.<sys>`, fleet-ren.md:308-309,471)
          bad = filter (k: k != c && (classes ? ${k} || channels ? ${k})) (attrNames res);
        in
        if bad != [ ] then
          throw "ren: channel `${c}` into: key `${builtins.head bad}` must be a top-level output"
        else
          res;
      chanFrags = concatMap (c: map (chanFrag c) (lib.unique (concatMap (receivers c) emissions.${c}))) (
        filter (c: channels.${c} ? into) (attrNames channels)
      );
      outputs = builtins.seq (builtins.deepSeq landed null) (
        L.mergeOutputs ([ collect.outputs ] ++ chanFrags)
      );
    in
    {
      inherit pools outputs emissions;
      inherit landed collect;
    };
}
