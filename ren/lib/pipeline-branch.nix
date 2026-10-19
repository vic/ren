# Class branch selection: the one branch of class c whose `at` matches scope id (branches are disjoint).
ren: {
  pipelineBranch =
    {
      lib,
      L,
      classes,
      matches,
      ...
    }:
    let
      inherit (builtins) elemAt filter length;
      bs = c: L.branches classes.${c};
    in
    rec {
      # branch index, or null when no branch matches
      branchIx =
        c: id:
        let
          m = filter (i: matches (elemAt (bs c) i) id) (lib.range 0 (length (bs c) - 1));
        in
        if m == [ ] then null else ren.gen.scope.folds.one "ren: class `${c}` branch at ${id}" m;
      branchAt =
        c: id:
        let
          i = branchIx c id;
        in
        if i == null then null else elemAt (bs c) i;
    };
}
