# class branches (README.md#open) + name checks (README.md#gen-mapping, README.md#den-coverage)
stimpy: {
  branches =
    {
      ren,
      st,
      ctx,
    }:
    let
      inherit (stimpy) lib pred;
      inherit (lib) attrNames;
      inherit (ren) classes channels;
      branchesOf = k: lib.toList classes.${k};
      # className -> id -> branch index | null
      branches = lib.mapAttrs (
        k: _:
        lib.genAttrs st.order (
          id:
          let
            hits = lib.filter (i: pred.match ctx (lib.elemAt (branchesOf k) i).at st.scopes.${id}) (
              lib.range 0 (lib.length (branchesOf k) - 1)
            );
          in
          if lib.length hits > 1 then
            throw "ren: class ${k}: branches not disjoint at ${id}"
          else
            lib.findFirst (_: true) null hits
        )
      ) classes;
      # shortcut: fixed module-arg list (A-F9), extend when a new module system needs it
      modArgs = lib.splitString " " "lib config options pkgs modulesPath specialArgs name extendModules moduleType osConfig nixosConfig";
      clash = lib.intersectLists (attrNames classes) (attrNames channels);
      argClash = lib.intersectLists modArgs (attrNames channels ++ attrNames ren.kinds);
    in
    {
      inherit branches;
      checks = [
        (clash == [ ] || throw "ren: class/channel name clash: ${toString clash}")
        (argClash == [ ] || throw "ren: names clash with module args: ${toString argClash}")
      ]
      ++ lib.concatMap (b: map (i: i == null || true) (lib.attrValues b)) (lib.attrValues branches);
    };
}
