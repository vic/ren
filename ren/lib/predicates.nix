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
      compile =
        {
          activeAt ? (_: _: false),
        }:
        p:
        let
          c = compile { inherit activeAt; };
        in
        # a kind ref matches its kind or any `is` descendant; an instance ref is id_hash identity
        if p.__ren == "kind" then
          s.subkind p.schema
        else if p.__ren == "instance" then
          s.entity p.__kind p
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
          s.${p.op} (map c p.args)
        else
          s.${p.op} (c p.args);
      test =
        ctx: opts: p: id:
        s.matches (compile opts p) id ctx;
      # nearest ancestor-or-self scope of id that carries x
      isAt =
        ctx: opts: P: x: id:
        test ctx opts P (
          ren.gen.prelude.findFirst (test ctx opts x)
            (throw "ren: is: ${x.__id or x.__scope or x.name} has no scope on path of ${id}")
            ([ id ] ++ ctx.ancestors id)
        );
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
      # ruling: `is P x` needs the current path (README.md#predicates); only a scope x carries one, load.nix tests it
      is =
        _: _:
        throw "ren: `is P x` with an instance needs the scope-local `is` from content args ({ is, ... }:)";
      # README.md#predicates `same a b`: gen-schema id_hash identity (registry entry, kinds-check.nix)
      same = a: b: a.id_hash == b.id_hash;
      # gen-select's scope adapter: `data` = the Ren scope plus __identity (instance entry, kind value)
      mkCtx =
        { kinds, sc }:
        gen.select.adapters.scope.mkContext {
          node = id: {
            parent = sc.parentOf id;
            scope = sc.scopes.${id};
            kindValue = kinds.${sc.scopes.${id}.kind}.schema;
          };
          get = id: _: ren.genLib.genAttrs (sc.children id) (_: null);
          project = n: n.scope;
          entryFor = id: sc.scopes.${id}.instance;
        }
        // {
          inherit (sc) order;
        };
      inherit compile test isAt;
    };
}
