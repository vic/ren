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
      renLib = stimpy.optLib // {
        inherit (pred)
          and
          anyOf
          not
          when
          within
          has
          same
          ;
        inherit (stimpy.scoped ctx) is nearest;
        inherit (stimpy) data flatten upTo;
        fold = stimpy.folds;
        # #48: lazy RESULT, no `outputs` (guarded `into` arg); deciding kinds or `at` from it cycles
        result = removeAttrs res [ "outputs" ];
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
      res = stimpy.result {
        inherit
          ren
          st
          act
          content
          pl
          col
          emissions
          ;
      };
    in
    res;
}
