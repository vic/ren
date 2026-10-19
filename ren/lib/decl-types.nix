# One kind or aspect declared in several files merges (fleet.md v33, vic/ren#19).
ren: {
  declTypes =
    let
      t = ren.genLib.types;
      opt = type: default: ren.genLib.mkOption { inherit type default; };
    in
    {
      # kind fields are gen-merge `raw` (equal merge, different clash); `below` concatenates;
      # a function kind (`{ db, region }: …`) has one definition
      kind = t.either t.function (
        t.submodule {
          freeformType = t.lazyAttrsOf t.raw;
          options = {
            below = opt (t.listOf t.raw) [ ];
            spawns = opt (t.lazyAttrsOf t.raw) { };
          };
        }
      );
      # gen-aspects `aspectModules` seam: class options are fixed `nullOr deferredModule`, so the raw
      # definitions are read here; a bare `final: prev:` class value is refused (fleet.md:454)
      bareClass =
        classes:
        { options, ... }:
        {
          meta.bare = builtins.any (k: builtins.any ren.content.isBare options.${k}.definitions) (
            builtins.attrNames classes
          );
        };
    };
}
