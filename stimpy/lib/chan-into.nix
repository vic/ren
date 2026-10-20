# README.md v35, README.md#channels: channel `into` once per receiving scope r with >=1 emission. A key naming a
# class forwards (as a module) to the nearest ancestor-or-self of r with that class's branch; a key
# naming another channel is refused; any other key (the channel's own name too) is an output.
stimpy: {
  chanInto =
    {
      ren,
      st,
      content, # content.branches: class -> id -> branch index | null
      argsAt,
      pools,
      call,
      cols, # class `into` calls: [ { k; id; r; } ]
    }:
    let
      inherit (stimpy) lib;
      inherit (lib) attrNames concatMap filter;
      inherit (ren) classes channels;
      withInto = filter (ch: channels.${ch} ? into) (attrNames channels);
      target =
        ch: r: k:
        lib.findFirst (t: content.branches.${k}.${t} != null)
          (throw "ren: channel `${ch}` at ${r} forwards to `${k}` but no scope has a `${k}` branch")
          ([ r ] ++ st.ancestors.${r});
      frag =
        ch: r: pool:
        let
          res = call channels.${ch}.into (argsAt r) pool;
          ks = attrNames res;
          bad = filter (k: k != ch && channels ? ${k}) ks;
          k = builtins.head bad;
          fk = filter (k: classes ? ${k}) ks;
        in
        if bad != [ ] then
          throw "ren: channel `${ch}` into: key `${k}` names a channel; channel `${ch}` cannot emit to channel `${k}`"
        else
          {
            out = removeAttrs res fk;
            fwd = map (k: {
              inherit k;
              from = r;
              t = target ch r k;
              m = {
                key = builtins.toJSON [
                  "chan"
                  ch
                  r
                  k
                ];
                imports = [ res.${k} ];
              };
            }) fk;
          };
      frags = concatMap (ch: lib.mapAttrsToList (frag ch) pools.${ch}) withInto;
      fwds = concatMap (f: f.fwd) frags;
      # stratum 3 probe: the keys only, without forcing the pool
      noPool = ch: throw "ren: channel `${ch}`: the keys an `into` returns must not depend on its pool";
      keysAt = ch: r: attrNames (call channels.${ch}.into (argsAt r) (noPool ch));
      classKeys =
        ch: lib.optionals (channels.${ch} ? into) (concatMap (keysAt ch) (attrNames pools.${ch}));
    in
    {
      inherit fwds;
      outputs = builtins.seq (builtins.deepSeq (map (f: f.t) fwds) null) (map (f: f.out) frags);
      fwdInto = k: id: map (f: f.m) (filter (f: f.k == k && f.t == id) fwds);
      cycle = stimpy.strata3 {
        inherit classes channels;
        classKeys = k: concatMap (c: attrNames c.r) (filter (c: c.k == k) cols);
        chanClasses = ch: filter (k: classes ? ${k}) (classKeys ch);
      };
    };
}
