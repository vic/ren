# README.md#helpers option shorthands `ren.lib.opt` / `ren.lib.maybe` (once the template's `ren.helpers`).
stimpy: {
  optLib = rec {
    opt = type: default: stimpy.lib.mkOption { inherit type default; };
    maybe = type: opt (stimpy.lib.types.nullOr type) null;
  };
}
