# Aspect activation = gen-program's well-founded model over one atom per (aspect, scope).
# Positive include cycles are legal; a negative cycle leaves atoms UNDEFINED and throws.
ren: {
  activation =
    let
      inherit (ren) gen predicates;
      inherit (builtins)
        attrNames
        concatMap
        concatStringsSep
        elem
        filter
        foldl'
        throw
        ;
      names = map (a: a.name);
      atom = a: s: "${a}@${s}";
      lit = pos: neg: { inherit pos neg; };
      one = [ (lit [ ] [ ]) ];
      cross = xs: ys: concatMap (x: map (y: lit (x.pos ++ y.pos) (x.neg ++ y.neg)) ys) xs;
      # not (C1 or C2 …) = and over i of (or over Ci's literals, each flipped)
      flip = c: map (x: lit [ ] [ x ]) c.pos ++ map (x: lit [ x ] [ ]) c.neg;
    in
    {
      mkActivation =
        {
          aspects,
          ctx,
        }:
        let
          ns = attrNames aspects;
          orSelf = s: [ s ] ++ ctx.ancestors s;
          # glue: compile `at` at scope s to a DNF over aspect atoms, [ { pos; neg; } ]
          dnf =
            p: s:
            if p.__ren == "aspect" then
              [ (lit [ (atom p.name s) ] [ ]) ]
            else if p.__ren != "pred" || p.op == "when" then
              (if predicates.test ctx { } p s then one else [ ])
            else if p.op == "and" then
              foldl' (acc: q: cross acc (dnf q s)) one p.args
            else if p.op == "anyOf" then
              concatMap (q: dnf q s) p.args
            else if p.op == "within" then
              concatMap (dnf p.args) (ctx.ancestors s)
            else if p.op == "has" then
              concatMap (dnf p.args) (ctx.children s)
            else
              foldl' (acc: c: cross acc (flip c)) one (dnf p.args s);
          by = field: a: filter (b: elem a (names aspects.${b}.${field})) ns;
          rules =
            a: s:
            let
              # not excluded(a,s): no excluder is active on an ancestor-or-self of s
              ex = concatMap (b: map (atom b) (orSelf s)) (by "excludes" a);
              inc = concatMap (b: map (t: lit [ (atom b t) ] [ ]) (orSelf s)) (by "includes" a);
              at = if aspects.${a}.at == null then [ ] else dnf aspects.${a}.at s;
            in
            map (c: {
              head = atom a s;
              inherit (c) pos;
              neg = c.neg ++ ex;
              relata = [ ];
            }) (at ++ inc);
          model = gen.program.model {
            program = gen.program.program [ ] (concatMap (a: concatMap (rules a) ctx.order) ns);
            interpretation = [ ];
            prior = null;
            complete = true;
          };
          checked =
            model.undefinedAtoms == [ ]
            || throw "ren: aspects not stratified: ${concatStringsSep ", " model.undefinedAtoms}";
          active = a: s: checked && (model.resolve (atom a s)).included;
        in
        {
          inherit active;
          activeAt = active;
        };
    };
}
