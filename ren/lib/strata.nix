# Stratum 3 (fleet-ren.md strata table, row 3): a class branch's `into` reads `outputs` only of
# class keys it does not forward into; reading one it does is a cycle, refused by a static check on
# the class graph. Graph edges come from the top-level keys each branch returns (probed lazily).
ren: {
  strata =
    {
      lib,
      classes,
      channels,
      L,
      sc,
      matches,
      renArgs,
      ...
    }:
    let
      inherit (builtins)
        any
        attrNames
        concatMap
        elem
        filter
        head
        ;
      inherit (ren.gen.graph) reachableFrom;
      classNames = attrNames classes;
      # per class, per branch: the scopes it runs at and the top-level keys it returns there
      info = lib.mapAttrs (
        c: cls:
        map (
          b:
          let
            ids = filter (matches b) sc.order;
            noOutputs = throw "ren: class `${c}`: the keys an `into` returns must not depend on `outputs`";
          in
          {
            inherit ids;
            keys = lib.unique (
              concatMap (id: attrNames (b.into (renArgs id // { outputs = noOutputs; }) [ ])) ids
            );
          }
        ) (L.branches cls)
      ) classes;
      fwdOf = filter (k: elem k classNames);
      forwards = c: concatMap (bi: fwdOf bi.keys) info.${c};
      # c plus the classes reachable from one of its branches' forwards (not c's other branches)
      reach = c: start: [ c ] ++ start ++ concatMap (reachableFrom { edges = forwards; }) start;
      produces =
        o:
        if elem o classNames || channels ? ${o} then
          [ ]
        else
          filter (c: any (bi: elem o bi.keys) info.${c}) classNames;
    in
    {
      # the `outputs` handed to class c's branch at scope id: lazy per key, throws only when read
      outputsFor =
        real: c: id:
        let
          r = reach c (fwdOf (head (filter (bi: elem id bi.ids) info.${c})).keys);
        in
        lib.mapAttrs (
          o: v:
          if any (k: elem k r) (produces o) then
            throw "ren: class `${c}` reads `outputs.${o}` produced by a class it forwards into (stratum 3)"
          else
            v
        ) real;
    };
}
