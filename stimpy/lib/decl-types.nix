# One kind or aspect declared in several files merges (fleet.md v33), with Ren's semantics.
stimpy: {
  declTypes =
    let
      inherit (stimpy) lib;
      t = lib.types;
      opt = type: default: lib.mkOption { inherit type default; };
      # Ren's gen-merge `raw`: equal definitions merge, different ones conflict
      eq = lib.mkOptionType {
        name = "raw";
        description = "raw value";
        merge = lib.mergeEqualOption;
      };
      isContentFn =
        f:
        lib.isFunction f
        && (lib.hasInfix "<attrspat" (builtins.toXML f) || f ? __functionArgs || f ? __functor);
      # class content: every file's module, in definition order; a bare `final: prev:` is refused (C5)
      modules = lib.mkOptionType {
        name = "classContent";
        merge =
          loc: defs:
          let
            vs = map (d: d.value) defs;
            a = lib.elemAt loc (lib.length loc - 2);
          in
          if lib.any (v: lib.isFunction v && !isContentFn v) vs then
            throw "ren: aspect ${a}: ${lib.last loc} must be a `{ ... }: v` function"
          else
            vs;
      };
      list = opt (t.listOf t.raw) [ ];
      # kind fields merge as `eq`, `below` concatenates; a function kind has one definition
      kind = t.either (t.addCheck t.raw lib.isFunction) (
        t.submodule {
          freeformType = t.lazyAttrsOf eq;
          options = {
            below = list;
            spawns = opt (t.lazyAttrsOf t.raw) { };
          };
        }
      );
      # classes: modules (null = no content); at and channels: eq; includes/excludes concatenate
      aspect =
        classes:
        t.submodule {
          freeformType = t.lazyAttrsOf eq;
          options = lib.mapAttrs (_: _: opt (t.nullOr modules) null) classes // {
            includes = list;
            excludes = list;
          };
        };
    in
    {
      inherit isContentFn kind aspect;
      # the `ren` option (QUORUM A-F3 layout); instances `ren.<kind>.<name>` are freeform
      fleet = t.submodule (
        { config, ... }:
        {
          freeformType = t.lazyAttrsOf (t.lazyAttrsOf t.deferredModule);
          options = lib.mapAttrs (_: type: opt (t.lazyAttrsOf type) { }) {
            kinds = kind;
            classes = t.raw;
            channels = t.raw;
            aspects = aspect config.classes;
          };
        }
      );
    };
}
