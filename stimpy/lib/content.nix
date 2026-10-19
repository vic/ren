# stratum 2 (fleet.md:96,99-100,426,450,534,575; C5): landed modules + emissions
stimpy: {
  content =
    {
      ren,
      st,
      act,
      ctx,
      argsAt, # id -> bindings ∪ pools ∪ { is }
    }:
    let
      inherit (stimpy) lib pred;
      inherit (lib) attrNames concatMap filter;
      inherit (ren) aspects classes channels;
      br = stimpy.branches { inherit ren st ctx; };
      inherit (br) branches;
      emitsAt = c: id: !(channels.${c} ? at) || pred.match ctx channels.${c}.at st.scopes.${id};
      lands =
        k: id:
        if classes ? ${k} then
          branches.${k}.${id} != null
        else if channels ? ${k} then
          emitsAt k id
        else
          throw "ren: unknown key ${k}"; # fleet.md:99
      keysOf = a: attrNames (removeAttrs aspects.${a} (lib.splitString " " "at includes excludes __ren"));
      checks =
        br.checks
        ++ concatMap (
          a:
          lib.optionals (act.active.${a} != [ ]) (
            map (
              k: lib.any (lands k) act.active.${a} || throw "ren: aspect ${a}: key ${k} lands nowhere" # fleet.md:100
            ) (keysOf a)
          )
        ) (attrNames aspects);
      aspectsAt = id: filter (a: lib.elem id act.active.${a}) (attrNames aspects);
      # fn content: Ren formals pre-applied, the rest stay module args
      wrap =
        a: id: ms:
        let
          mod =
            m:
            let
              fa = lib.functionArgs m;
              mine = builtins.intersectAttrs fa (argsAt id);
            in
            if lib.isFunction m then
              lib.setFunctionArgs (margs: m (margs // mine)) (removeAttrs fa (attrNames mine))
            else
              m;
        in
        {
          key = builtins.toJSON [
            a
            st.scopes.${id}.__ren.path
          ];
          _file = "ren:${a}";
          imports = map mod ms; # one module per file that defines the class (decl-types.nix)
        };
      inherit (stimpy.declTypes) isContentFn;
      emit =
        a: id: c:
        let
          f = aspects.${a}.${c};
          args = argsAt id // {
            inherit lib;
          };
        in
        if isContentFn f then
          f (builtins.intersectAttrs (lib.functionArgs f) args)
        else
          throw "ren: aspect ${a}: ${c} must be a `{ ... }: v` function"; # C5
      perScope = id: concatMap (a: map (k: { inherit a k; }) (keysOf a)) (aspectsAt id);
      landedOf =
        k: f:
        lib.filterAttrs (_: v: v != [ ]) (
          lib.genAttrs st.order (id: map (x: f x.a id) (filter (x: x.k == k && lands k id) (perScope id)))
        );
    in
    {
      inherit branches checks;
      landed = lib.mapAttrs (k: _: landedOf k (a: _: a)) classes;
      modules = lib.mapAttrs (k: _: landedOf k (a: id: wrap a id aspects.${a}.${k})) classes;
      # channel -> [ { id; v; } ] in scope-path order, aspects by name
      emissions = lib.mapAttrs (
        c: _:
        concatMap (
          id:
          map (x: {
            inherit id;
            n = x.a;
            v = emit x.a id c;
          }) (filter (x: x.k == c && emitsAt c id) (perScope id))
        ) st.order
      ) channels;
    };
}
