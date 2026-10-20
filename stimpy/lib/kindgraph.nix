# stratum 0 kind graph (README.md#open, README.md#features; README.md#kinds): below/spawns/is over raw kind decls
stimpy: {
  kindgraph =
    { ren, rawKinds }:
    let
      inherit (stimpy) lib;
      inherit (lib) attrNames concatMap elem;
      kindNames = attrNames rawKinds;
      fnArgs = K: if lib.isFunction rawKinds.${K} then lib.functionArgs rawKinds.${K} else { };
      body =
        K:
        let
          d = rawKinds.${K};
        in
        if lib.isFunction d then d (lib.mapAttrs (n: _: ren.kinds.${n}) (fnArgs K)) else d;
      below = K: map (k: k.__ren.kind) (body K).below or [ ];
      kindsOf = K: [ K ] ++ (if (body K) ? is then kindsOf (body K).is.__ren.kind else [ ]);
      # README.md#features gen-scope refuses a cyclic or self-naming `below`
      reach =
        seen: K:
        if elem K seen then
          throw "ren: cycle in below at kind ${K}"
        else
          lib.all (reach (seen ++ [ K ])) (below K);
      spawnsOk =
        K:
        let
          bad = lib.subtractLists (below K) (attrNames (body K).spawns or { });
        in
        bad == [ ] || throw "ren: kind ${K}: spawns ${toString bad} not in below"; # README.md#open
      listed = concatMap below kindNames;
    in
    {
      inherit
        fnArgs
        body
        below
        kindsOf
        ;
      ok = lib.all (K: reach [ ] K && spawnsOk K) kindNames;
      roots = lib.filter (K: below K != [ ] && !elem K listed) kindNames; # README.md#kinds
    };
}
