# Channel `into` (README.md v35), once per receiving scope r with the folded pool. A returned key that
# names a class forwards (as a module) to the nearest ancestor-or-self of r with that class's branch;
# one naming another channel is refused; any other key (the channel's own name too) is an output.
ren: {
  pipelineChan =
    {
      lib,
      channels,
      classes,
      sc,
      branchAt,
      renArgs,
      pools,
      receivers,
      emissions,
      ...
    }:
    let
      inherit (builtins) attrNames concatMap filter;
      withInto = filter (c: channels.${c} ? into) (attrNames channels);
      recvs = c: lib.unique (concatMap (receivers c) emissions.${c});
      isFwd = k: classes ? ${k};
      target =
        c: r: k:
        ren.gen.prelude.findFirst (t: branchAt k t != null)
          (throw "ren: channel `${c}` at ${r} forwards to `${k}` but no scope has a `${k}` branch")
          ([ r ] ++ sc.ancestors r);
      frag =
        c: r:
        let
          res = channels.${c}.into (renArgs r) (pools.${c} r);
          ks = attrNames res;
          chan = filter (k: k != c && channels ? ${k}) ks;
          k = builtins.head chan;
        in
        if chan != [ ] then
          throw "ren: channel `${c}` into: key `${k}` names a channel; channel `${c}` cannot emit to channel `${k}`"
        else
          {
            out = removeAttrs res (filter isFwd ks);
            fwd = map (k: {
              inherit k;
              t = target c r k;
              v = res.${k};
            }) (filter isFwd ks);
          };
      frags = concatMap (c: map (frag c) (recvs c)) withInto;
      fwds = concatMap (f: f.fwd) frags;
      # stratum 3 probe: the keys only, without forcing the pool
      noPool = c: throw "ren: channel `${c}`: the keys an `into` returns must not depend on its pool";
      keysAt = c: r: attrNames (channels.${c}.into (renArgs r) (noPool c));
    in
    {
      outputs = builtins.seq (builtins.deepSeq (map (f: f.t) fwds) null) (map (f: f.out) frags);
      fwdTo = k: t: map (f: f.v) (filter (f: f.k == k && f.t == t) fwds);
      classKeys =
        c: if channels.${c} ? into then lib.unique (filter isFwd (concatMap (keysAt c) (recvs c))) else [ ];
    };
}
