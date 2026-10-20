# pipeline tail: emissions -> pools -> class collect -> channel `into` -> merged outputs.
ren: {
  pipelineOut =
    args@{
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
          c: id:
          map (l: C.classModule (renArgs id) (content l.n c)) (filter (l: l.id == id) (at c))
          ++ chan.fwdTo c id;
      };
      # ruling: channel `at` is the emitter scopes, also for emissions from a class `into` (fleet-ren.md:26,102)
      outside =
        c: e:
        if channels.${c} ? at && !test channels.${c}.at e.path then
          throw "ren: class `${e.class}` at ${e.path} emits channel `${c}` outside its `at`"
        else
          e;
      emissions = lib.mapAttrs (
        c: ch:
        map (ren.typedEmission c ch) (
          map (l: {
            inherit (l) n;
            path = l.id;
            value = C.callContent (renArgs l.id) (content l.n c);
          }) (at c)
          ++ map (outside c) (filter (e: e.channel == c) collect.emissions)
        )
      ) channels;
      pools = C.mkPools { inherit channels emissions receivers; } sc.order;
      chan = ren.pipelineChan (args // { inherit pools emissions; });
      cycle = strata.cycle chan.classKeys;
      outputs = builtins.seq (builtins.deepSeq landed null) (
        builtins.seq cycle (L.mergeOutputs ([ collect.outputs ] ++ chan.outputs))
      );
    in
    {
      inherit
        pools
        outputs
        emissions
        cycle
        ;
      inherit landed collect;
    };
}
