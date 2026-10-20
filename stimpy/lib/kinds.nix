stimpy: {
  # an instance is a module: nixpkgs module keys (unifyModuleSyntax), the same list as Ren's
  # (gen-merge moduleSyntax.shorthandMeta ++ structuring), plus Ren's instance internals (#22)
  reservedFields = stimpy.lib.splitString " " "_class _file key disabledModules require imports freeformType _module __pureModule __reservedKeys __keyEq config options __id __kind __ren _identity _identityKeys id_hash kind name lib pkgs";
  # an instance's kind fields alone (#23): no field is reserved, so strip every reserved name
  data = inst: removeAttrs inst stimpy.reservedFields;
  kinds =
    cfg: kinds:
    let
      inherit (stimpy) lib;
      reserved = stimpy.reservedFields;
      kindKeys = [
        "below"
        "spawns"
        "is"
      ];
    in
    rec {
      # README.md#topology function kind `{ db, region }: when p { }`: args = ref fields typed by kinds.<arg>;
      # body = `when p` applied to fields ⟹ fields // { __guard = p; } (pred `when` node is a functor).
      decl =
        K:
        let
          d = cfg.kinds.${K} or (throw "ren: unknown kind ${K}");
          args = lib.mapAttrs (n: _: kinds.${n} or (throw "ren: kind ${K}: unknown kind ${n}")) (
            lib.functionArgs d
          );
          body = if lib.isFunction d then args // d args else d;
          own = removeAttrs body (kindKeys ++ [ "__guard" ]);
          bad = lib.intersectLists reserved (lib.attrNames own);
        in
        if bad != [ ] then
          throw "ren: kind `${K}`: field `${lib.head bad}` is reserved (${toString reserved})"
        else
          {
            inherit body own;
            guard = body.__guard or null;
          };

      superOf =
        K:
        let
          b = (decl K).body;
        in
        if b ? is then b.is.__ren.kind else null;

      # [K super super's-super …]; cycle ⟹ throw
      kindsOf =
        K:
        let
          go =
            seen: k:
            if lib.elem k seen then
              throw "ren: cycle in `is` at kind ${k}"
            else
              [ k ] ++ (if superOf k == null then [ ] else go (seen ++ [ k ]) (superOf k));
        in
        go [ ] K;

      family = K: lib.last (kindsOf K);

      # QUORUM A-F7: superFields // ownFields
      fieldOpts =
        K:
        lib.mapAttrs (_: v: if lib.isOption v then v else lib.mkOption { type = v; }) (
          lib.foldr (k: acc: acc // (decl k).own) { } (kindsOf K)
        );

      ref =
        K:
        lib.mkOptionType {
          name = "ren kind ${K}";
          check = v: v ? __ren && v.__ren.ref or null == "inst" && lib.elem K (kindsOf v.__ren.kind);
          # QUORUM A-F2: identity merge, not mergeEqualOption (cyclic graphs)
          merge =
            loc: defs:
            let
              ids = map (d: d.value.__ren.id) defs;
            in
            if lib.all (i: i == lib.head ids) ids then
              (lib.head defs).value
            else
              throw "ren: conflicting refs at ${lib.showOption loc}";
        }
        // {
          __ren = {
            ref = "kind";
            kind = K;
          };
        };
    };
}
