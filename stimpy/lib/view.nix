stimpy: {
  view =
    let
      inherit (stimpy) lib;
      t = lib.types;
      declared = [
        "kinds"
        "classes"
        "channels"
        "aspects"
      ];

      mkView =
        renLib: cfg:
        let
          k = stimpy.kinds cfg kinds;
          kinds = lib.mapAttrs (K: _: k.ref K) cfg.kinds;
          insts = removeAttrs cfg (declared ++ [ "lib" ]);
          id = K: n: "${k.family K}/${n}";
          inst =
            K: n: m:
            (lib.evalModules {
              modules = [
                m
                { options = k.fieldOpts K; }
              ];
            }).config
            // {
              name = n;
              __ren = {
                ref = "inst";
                kind = K;
                id = id K n;
              };
            };
          instances = lib.mapAttrs (
            K: ms: if cfg.kinds ? ${K} then lib.mapAttrs (inst K) ms else throw "ren: unknown kind ${K}"
          ) insts;
          entries = lib.concatLists (
            lib.mapAttrsToList (
              K: ms:
              map (n: {
                inherit K n;
                id = id K n;
              }) (lib.attrNames ms)
            ) insts
          );
          dup = # fleet.md:448 at most one name per is-family
            _: xs:
            lib.length xs == 1
            || throw "ren: duplicate instance name ${(lib.head xs).n} in kinds ${
              lib.concatMapStringsSep "," (x: x.K) xs
            }";
        in
        lib.mapAttrs (_: _: { }) cfg.kinds
        // instances
        // {
          lib = renLib;
          inherit kinds;
          inherit (cfg) classes channels;
          aspects = lib.mapAttrs (
            a: v:
            lib.filterAttrs (k: x: !(cfg.classes ? ${k}) || x != null) v # unset class: `null` (decl-types.nix)
            // {
              __ren = {
                ref = "aspect";
                name = a;
              };
            }
          ) cfg.aspects;
          __ren = {
            guard = K: (k.decl K).guard;
            checks = # kernel forces: lib.all lib.id checks
              lib.mapAttrsToList (K: _: builtins.seq (k.kindsOf K) (builtins.seq (k.decl K) true)) cfg.kinds
              ++ lib.mapAttrsToList (K: _: builtins.seq instances.${K} true) insts
              ++ lib.mapAttrsToList dup (lib.groupBy (x: x.id) entries);
          };
        };
    in
    {
      inherit mkView;
      # QUORUM A-F3 layout; renLib arrives as module arg (kernel sets _module.args.renLib)
      module =
        { config, renLib, ... }:
        {
          options.ren = lib.mkOption {
            default = { };
            type = stimpy.declTypes.fleet;
          };
          config._module.args.ren = mkView renLib config.ren;
        };
    };
}
