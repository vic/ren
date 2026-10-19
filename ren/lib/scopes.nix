# The scope tree is grown by gen-scope: roots are gen nodes, every child comes from a gen `spawns` builder.
# glue: gen.scope.mkKinds refuses a kind in its own `below` ("a kind naming itself, or a cycle of kinds,
# has no such order"), but Ren kinds may recurse (bounded by once-per-path). So gen kinds are DEPTH
# levels d0..dM (M = instance count: a deeper path must repeat an instance); Ren's kind rides in decls.
# glue: gen keys spawned nodes by id (attrset order), so Ren's preorder is rebuilt from a rank path.
ren: {
  scopes =
    let
      inherit (ren) gen;
      inherit (builtins)
        attrNames
        concatMap
        elem
        filter
        genList
        length
        listToAttrs
        mapAttrs
        sort
        ;
      G = gen.scope;
      inherit (gen.prelude) imap0 nameValuePair;
      dk = i: "d${toString i}";
    in
    {
      mkScopes =
        { kinds, instances }:
        let
          isChain = k: [ k ] ++ (if kinds.${k}.is or null == null then [ ] else isChain kinds.${k}.is);
          below = k: kinds.${k}.below or [ ];
          listed = concatMap below (attrNames kinds);
          roots = filter (k: below k != [ ] && !(elem k listed)) (attrNames kinds);
          all = k: instances.${k} or { };
          insts = k: map (n: (all k).${n}) (attrNames (all k));

          childrenOf =
            s:
            let
              k = s.kind;
              sp = kinds.${k}.spawns or { };
              bad = filter (b: !(elem b (below k))) (attrNames sp);
            in
            if bad != [ ] then
              throw "ren: kind `${k}` spawns `${builtins.head bad}` not in below"
            else
              concatMap (
                b:
                let
                  m = (sp.${b} or (_: all b)) s;
                in
                map (n: m.${n}) (attrNames m)
              ) (below k);

          mkNode = ren.scopesNode isChain;

          spawn =
            i: self: pid:
            let
              p = (self.node pid).decls;
            in
            listToAttrs (imap0 (mkNode p) (childrenOf p.scope));
          M = length (concatMap insts (attrNames instances));
          level =
            i:
            G.mkKind (
              if i == M then
                { }
              else
                {
                  below = [ (dk (i + 1)) ];
                  spawns.${dk (i + 1)} = spawn i;
                }
            ) (dk i);
          rootNodes = imap0 (mkNode { }) (concatMap insts roots);
          g = G.eval { parseParent = ren.scopesParent; } { children = _: _: { }; } {
            # gen stamps a spawned node's id, `type` and `parent` (its host); only roots state theirs.
            nodes = mapAttrs (
              id: n:
              n
              // {
                inherit id;
                type = dk 0;
                parent = null;
              }
            ) (listToAttrs rootNodes);
            nodeOrder = map (n: n.name) rootNodes;
            kinds = G.mkKinds (genList (j: level (M - j)) (M + 1));
          };
          nodes = sort (a: b: a.decls.rank < b.decls.rank) (map g.node g.allNodeIds);
          byId = listToAttrs (map (n: nameValuePair n.id n) nodes);
        in
        {
          scopes = mapAttrs (_: n: n.decls.scope) byId;
          order = map (n: n.id) nodes;
          children = id: map (n: n.id) (filter (n: n.parent == id) nodes);
          parentOf = G.parent g;
          ancestors = G.ancestors g;
        };
    };
}
