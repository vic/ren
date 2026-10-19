# stratum 3 (fleet.md:90-92,145-152,300-306,427,457; C6): collectors
stimpy: {
  collect =
    {
      ren,
      st,
      content,
      argsAt, # id -> bindings ∪ pools ∪ { is }
      pools, # channel -> receiver id -> value
    }:
    let
      inherit (stimpy) lib merge;
      inherit (lib) attrNames concatMap filter;
      inherit (ren) classes channels;
      call = f: args: f (builtins.intersectAttrs (lib.functionArgs f) (args // { inherit outputs; }));
      # one class `into` call per (class, scope matching a branch); keys static (A-F10), ms stays lazy
      cols = concatMap (
        k:
        concatMap (
          id:
          let
            i = content.branches.${k}.${id};
            into = (lib.elemAt (lib.toList classes.${k}) i).into;
            ms = content.modules.${k}.${id} or [ ] ++ map (f: f.m) (fwdInto k id);
          in
          lib.optional (i != null) {
            inherit k id into;
            r = call into (argsAt id) ms;
          }
        ) st.order
      ) (attrNames classes);
      # fleet.md:149-152 nearest ancestor-or-self where class j matches; t != s if j == k
      target =
        c: j:
        lib.findFirst (t: content.branches.${j}.${t} != null)
          (throw "ren: ${c.k} at ${c.id}: no ${j} scope to forward into")
          ((if j == c.k then [ ] else [ c.id ]) ++ st.ancestors.${c.id});
      # a class's own name forwards up only if an ancestor has that class, else it is an output
      fwdKeys =
        c:
        filter (
          j:
          classes ? ${j} && (j != c.k || lib.any (t: content.branches.${j}.${t} != null) st.ancestors.${c.id})
        ) (attrNames c.r);
      fwds = concatMap (
        c:
        map (j: {
          inherit j;
          from = c.id;
          t = target c j;
          m = {
            key = builtins.toJSON [
              "fwd"
              c.id
              j
            ];
            imports = [ c.r.${j} ];
          };
        }) (fwdKeys c)
      ) cols;
      fwdInto = k: id: filter (f: f.j == k && f.t == id) fwds;
      # channel -> [ { id; v; } ] emitted by collectors
      intoEmissions = lib.mapAttrs (
        ch: _:
        concatMap (
          c:
          lib.optional (c.r ? ${ch}) {
            inherit (c) id;
            v = c.r.${ch};
          }
        ) cols
      ) channels;
      # C6: channel into once per receiving scope with >=1 emission
      chanOuts = concatMap (
        ch:
        lib.optionals (channels.${ch} ? into) (
          lib.mapAttrsToList (r: pool: call channels.${ch}.into (argsAt r) pool) pools.${ch}
        )
      ) (attrNames channels);
      outputs = merge.mergeStrict [ ] (
        [ { } ] ++ map (c: removeAttrs c.r (fwdKeys c ++ attrNames channels)) cols ++ chanOuts
      );
      # fleet.md:427,457
      checks =
        map (
          c:
          !(lib.functionArgs c.into ? outputs && fwdKeys c != [ ])
          || throw "ren: stratum 3 cycle: ${c.k} at ${c.id} reads outputs and forwards"
        ) cols
        ++ map (f: builtins.seq f.t true) fwds;
    in
    {
      inherit outputs intoEmissions checks;
      forwarded = lib.mapAttrs (
        j: _: lib.mapAttrs (_: map (f: f.from)) (lib.groupBy (f: f.t) (filter (f: f.j == j) fwds))
      ) classes;
    };
}
