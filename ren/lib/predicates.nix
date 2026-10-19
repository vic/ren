# Ren predicates -> gen-select selectors.
ren: {
  predicates =
    let
      inherit (ren) gen;
      s = gen.select;
      mk = op: args: {
        __ren = "pred";
        inherit op args;
      };
      ops = {
        and = s.and;
        anyOf = s.anyOf;
        not = s.not;
        within = s.within;
        has = s.has;
      };
      compile =
        {
          activeAt ? (_: _: false),
        }:
        p:
        let
          c = compile { inherit activeAt; };
          kindOf = id: ctx: (ctx.data id).kinds;
        in
        if p.__ren == "kind" then
          s.when (id: ctx: builtins.elem p.name (kindOf id ctx))
        else if p.__ren == "instance" then
          s.when (id: ctx: (ctx.data id).instance.__id == p.__id)
        else if p.__ren == "scope" then
          s.when (id: _: id == p.__scope)
        else if p.__ren == "aspect" then
          s.when (id: _: activeAt p.name id)
        else if p.op == "when" then
          s.when (id: ctx: p.args (ctx.data id))
        else if
          builtins.elem p.op [
            "and"
            "anyOf"
          ]
        then
          ops.${p.op} (map c p.args)
        else
          ops.${p.op} (c p.args);
      test =
        ctx: opts: p: id:
        s.matches (compile opts p) id ctx;
      # nearest ancestor-or-self scope of id that carries x
      isAt =
        ctx: opts: P: x: id:
        let
          hit = sid: if x.__ren == "scope" then sid == x.__scope else (ctx.data sid).instance.__id == x.__id;
          found = builtins.filter hit ([ id ] ++ ctx.ancestors id);
        in
        if found == [ ] then
          throw "ren: is: ${x.__id or x.__scope or x.name} has no scope on path of ${id}"
        else
          test ctx opts P (builtins.head found);
    in
    {
      and = ps: mk "and" ps;
      anyOf = ps: mk "anyOf" ps;
      not = p: mk "not" p;
      within = p: mk "within" p;
      has = p: mk "has" p;
      # `when f` is a pred; `when P body` (fn-form kind decl) is the guarded-body record kinds.nix reads.
      when =
        f:
        mk "when" f
        // {
          __functor = _: body: {
            __ren = "when";
            pred = mk "when" f;
            inherit body;
          };
        };
      # ruling: `is P x` needs the current path (fleet-ren.md:113); only a scope x carries one, load.nix tests it
      is =
        _: _:
        throw "ren: `is P x` with an instance needs the scope-local `is` from content args ({ is, ... }:)";
      # fleet-ren.md `same a b`: gen-schema id_hash identity (registry entry, kinds-check.nix)
      same = a: b: a.id_hash == b.id_hash;
      inherit compile test isAt;
    };
}
