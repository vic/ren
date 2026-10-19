# evalFleet: view → strata 0-3 (design "evalFleet RESULT")
stimpy: {
  mkFlake = inputs: module: (stimpy.evalFleet inputs module).outputs;
  evalFleet =
    inputs: module:
    let
      inherit (stimpy)
        lib
        pred
        view
        ;
      result = lib.evalModules {
        modules = [
          (view.module renLib)
          { _module.args = { inherit inputs; }; }
          module
        ];
      };
      ren = result._module.args.ren;
      renLib = {
        inherit (pred)
          and
          anyOf
          not
          when
          within
          has
          same
          ;
        is = pred.is ctx;
        inherit (stimpy) data;
        fold = stimpy.folds;
      };
      scopesOf = map (i: st.scopes.${i});
      ctx = {
        inherit (act) activeAt;
        children = s: scopesOf st.children.${s.__ren.id};
        ancestors = s: scopesOf st.ancestors.${s.__ren.id};
      };
      st = stimpy.scopes {
        inherit ren;
        rawKinds = result.config.ren.kinds;
        ctx = ctx // {
          activeAt = a: _: throw "ren: aspect ${a} read in stratum 0";
        };
      };
      act = stimpy.activation {
        inherit (ren) aspects;
        inherit st ctx;
      };
      argsAt =
        id:
        removeAttrs st.scopes.${id} [ "__ren" ]
        // pl.poolsAt id
        // {
          is = pred.is ctx;
        };
      content = stimpy.content {
        inherit
          ren
          st
          act
          ctx
          argsAt
          ;
      };
      pos = lib.listToAttrs (lib.imap0 (i: id: lib.nameValuePair id i) st.order);
      emissions = lib.mapAttrs (
        c: es: builtins.sort (x: y: pos.${x.id} < pos.${y.id}) (es ++ col.intoEmissions.${c})
      ) content.emissions;
      pl = stimpy.pools {
        inherit (ren) channels;
        inherit st ctx emissions;
      };
      col = stimpy.collect {
        inherit
          ren
          st
          content
          argsAt
          ;
        inherit (pl) pools;
      };
      c0 = lib.all lib.id ren.__ren.checks;
      c2 = c0 && lib.all lib.id content.checks;
      c3 = c2 && lib.all lib.id col.checks;
      after = ok: lib.mapAttrs (_: builtins.seq ok);
    in
    after c0 {
      inherit (st) scopes;
      inherit (act) active;
    }
    // after c2 {
      inherit (content) landed;
      inherit (pl) pools;
      branches = lib.mapAttrs (_: lib.filterAttrs (_: i: i != null)) content.branches;
      emitted = lib.mapAttrs (_: es: lib.unique (map (e: e.id) es)) emissions;
    }
    // after c3 { inherit (col) outputs forwarded; };
}
