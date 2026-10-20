# README.md#helpers option shorthands `ren.lib.opt` / `ren.lib.maybe` (once the template's `ren.helpers`).
ren: {
  optLib = rec {
    opt = type: default: ren.genLib.mkOption { inherit type default; };
    maybe = type: opt (ren.genLib.types.nullOr type) null;
  };
}
