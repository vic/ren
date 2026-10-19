# Classes: branch = { at; into; }; a class is a branch or a list of branches.
# mkCollect runs each class branch per scope and routes every key of its result:
#   class name -> forwarded (as a module) to the nearest scope with that class's branch
#   channel    -> emission; anything else -> output fragment.
ren: {
  classes =
    let
      inherit (ren) folds;
      branches = c: if builtins.isList c then c else [ c ];
      mergeOutputs =
        frags:
        folds.attrs.apply "outputs" (
          map (value: {
            path = "";
            inherit value;
          }) frags
        );
      mkCollect =
        {
          classes,
          channelNames,
          branchAt,
          scopeOrder,
          ancestors,
          renArgsAt,
          # per-(class, scope) args over renArgsAt: the stratum-guarded `outputs` (strata.nix)
          argsFor ? (_: _: { }),
          contentModules,
        }:
        let
          classNames = builtins.attrNames classes;
          inherit (builtins)
            attrNames
            concatMap
            elem
            filter
            ;
          key = c: id: "${c}@${id}";
          # lazy fixpoint: a scope's ms read the forwards routed to it, so class order never matters
          pairs = concatMap (
            id: map (c: { inherit c id; }) (filter (c: branchAt c id != null) classNames)
          ) scopeOrder;
          res = builtins.listToAttrs (
            map (p: {
              name = key p.c p.id;
              value = (branchAt p.c p.id).into (renArgsAt p.id // argsFor p.c p.id) (
                contentModules p.c p.id ++ forwardedTo p.c p.id
              );
            }) pairs
          );
          target =
            c: id: k:
            ren.gen.prelude.findFirst (t: branchAt k t != null && !(k == c && t == id))
              (throw "ren: class `${c}` at ${id} forwards to `${k}` but no scope has a `${k}` branch")
              ([ id ] ++ ancestors id);
          # scopeOrder is children first, so forwards keep child-before-parent order
          routed = concatMap (
            p:
            map (
              k:
              p
              // {
                inherit k;
                v = res.${key p.c p.id}.${k};
              }
            ) (attrNames res.${key p.c p.id})
          ) pairs;
          fwd = filter (r: elem r.k classNames) routed;
          forwardedTo = c: id: map (r: r.v) (filter (r: r.k == c && target r.c r.id r.k == id) fwd);
          rest = filter (r: !(elem r.k classNames)) routed;
          isChan = r: elem r.k channelNames;
        in
        {
          outputs = builtins.seq (builtins.deepSeq (map (r: target r.c r.id r.k) fwd) null) (
            mergeOutputs (map (r: { ${r.k} = r.v; }) (filter (r: !(isChan r)) rest))
          );
          emissions = map (r: {
            channel = r.k;
            class = r.c;
            path = r.id;
            value = r.v;
          }) (filter isChan rest);
          inherit fwd target;
        };
    in
    {
      inherit branches mkCollect mergeOutputs;
    };
}
