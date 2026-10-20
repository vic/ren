# stratum 3 (README.md#open, README.md#topology, README.md#hosts, README.md#features; README.md#channels): collectors
stimpy: {
  collect =
    args@{
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
      call = f: args: f (builtins.intersectAttrs (lib.functionArgs f) ({ inherit outputs; } // args));
      # one class `into` call per (class, scope matching a branch); keys static (A-F10), ms stays lazy
      cols = concatMap (
        k:
        concatMap (
          id:
          let
            i = content.branches.${k}.${id};
            into = (lib.elemAt (lib.toList classes.${k}) i).into;
            ms = content.modules.${k}.${id} or [ ] ++ map (f: f.m) (fwdInto k id) ++ chan.fwdInto k id;
          in
          lib.optional (i != null) (
            lib.fix (c: {
              inherit k id into;
              r = call into (argsAt id // { outputs = guard c; }) ms;
            })
          )
        ) st.order
      ) (attrNames classes);
      # README.md#platforms nearest ancestor-or-self where class j matches; t != s if j == k
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
            class = c.k;
            v = c.r.${ch};
          }
        ) cols
      ) channels;
      chan = stimpy.chanInto (args // { inherit call cols; });
      outOf = c: removeAttrs c.r (fwdKeys c ++ attrNames channels);
      outputs = merge.mergeStrict [ ] ([ { } ] ++ map outOf cols ++ chan.outputs);
      guard = stimpy.outputsFor {
        inherit cols fwdKeys outputs;
        outKeys = c: attrNames (outOf c);
      };
      # README.md#features
      checks = map (f: builtins.seq f.t true) fwds ++ [ chan.cycle ];
    in
    {
      inherit
        outputs
        intoEmissions
        checks
        fwds
        ;
      inherit (chan) cycle;
      chanFwds = chan.fwds;
    };
}
