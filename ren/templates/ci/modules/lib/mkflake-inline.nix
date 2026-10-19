{ ren, lib }:
let
  inherit (import ../../fixtures/mkflake.nix { inherit ren lib; }) inputs;
  # mini fleet: class `sys` at box; aspect `a` includes inline aspects (fleet.md:511,576)
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
    test-inline-named-lands = {
      expr =
        (mini (ren: [
          {
            name = "base";
            sys.n = 1;
          }
        ])).outputs.got;
      expected.n = 1;
    };
    test-inline-unnamed-keyed-taker-index = {
      expr =
        (mini (ren: [
          ren.aspects.ref
          { sys.u = 2; }
        ])).active;
      expected = {
        a = [ "root:r/box:b" ];
        ref = [ "root:r/box:b" ];
        "a/1" = [ "root:r/box:b" ];
      };
    };
    test-inline-unnamed-lands = {
      expr =
        (mini (ren: [
          ren.aspects.ref
          { sys.u = 2; }
        ])).outputs.got;
      expected = {
        r = 1;
        u = 2;
      };
    };
    # an inline must not silently replace a declared aspect of the same name
    test-inline-name-of-declared = {
      expr =
        (mini (ren: [
          {
            name = "ref";
            sys.n = 1;
          }
        ])).active;
      expectedError.type = "ThrownError";
      expectedError.msg = "has the name of a declared aspect";
    };
  };
}
