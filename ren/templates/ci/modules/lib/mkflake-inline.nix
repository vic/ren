{ ren, lib }:
let
  inherit (import ../../fixtures/mkflake.nix { inherit ren lib; }) inputs;
  # mini fleet: class `sys` at box; aspect `a` includes `inc ren` (inline aspects refused, #21)
  mini = miniWith { };
  # `extra`: a second fleet module (one aspect defined in two files merges)
  miniWith =
    extra: inc:
    ren.evalFleet inputs (
      { ren, ... }:
      {
        imports = [ extra ];
        ren.classes.sys = {
          at = ren.kinds.box;
          # class values are modules: evaluate them, never read them as data
          into = _: ms: {
            got =
              (lib.evalModules { modules = [ { freeformType = lib.types.lazyAttrsOf lib.types.raw; } ] ++ ms; })
              .config;
          };
        };
        ren.kinds = {
          root.below = [ ren.kinds.box ];
          box = { };
        };
        ren.root.r = { };
        ren.box.b = { };
        ren.aspects.a = {
          at = ren.kinds.box;
          includes = inc ren;
        };
        ren.aspects.ref.sys.r = 1;
      }
    );
  refused = i: {
    expectedError.type = "ThrownError";
    expectedError.msg = "ren: aspect `a`: includes\\[${toString i}\\] is not a ref to a declared aspect";
  };
in
{
  mkflake-inline = {
    # gen-aspects merge: class content of `ref` from two modules lands together
    test-aspect-two-modules-merge = {
      expr = (miniWith { ren.aspects.ref.sys.s = 3; } (ren: [ ren.aspects.ref ])).outputs.got;
      expected = {
        r = 1;
        s = 3;
      };
    };
    # negative control: two modules giving one class option two values is a merge conflict
    test-aspect-two-modules-conflict = {
      expr = (miniWith { ren.aspects.ref.sys.r = 2; } (ren: [ ren.aspects.ref ])).outputs.got.r;
      expectedError.type = "ThrownError";
      expectedError.msg = "the option `r' has conflicting definitions";
    };
    # control: a ref to a declared aspect lands
    test-include-ref-lands = {
      expr = (mini (ren: [ ren.aspects.ref ])).outputs.got;
      expected.r = 1;
    };
    test-inline-named-refused = refused 0 // {
      expr =
        (mini (ren: [
          {
            name = "base";
            sys.n = 1;
          }
        ])).active;
    };
    test-inline-unnamed-refused = refused 1 // {
      expr =
        (mini (ren: [
          ren.aspects.ref
          { sys.u = 2; }
        ])).active;
    };
    # an inline with a declared aspect's name is still not a ref
    test-inline-name-of-declared-refused = refused 0 // {
      expr =
        (mini (ren: [
          {
            name = "ref";
            sys.n = 1;
          }
        ])).active;
    };
  };
}
