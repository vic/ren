# one kind or aspect declared in several files merges (README.md v33, vic/ren#19), as in Ren
{ lib, stimpy }:
let
  t = lib.types;
  eval =
    ms:
    (lib.evalModules {
      modules = [
        (stimpy.view.module { })
        {
          ren.classes.sys = { };
          ren.kinds.box.below = [ "b" ];
          ren.aspects.z = {
            at = "box";
            sys.a = 1;
            excludes = [ "x" ];
          };
        }
      ]
      ++ ms;
    }).config.ren;
  more = {
    ren.kinds.box = {
      below = [ "c" ];
      spawns.c = 1;
      size = t.int;
    };
    ren.aspects.z = {
      at = "box";
      sys.b = 2;
      excludes = [ "y" ];
    };
  };
  err.type = "ThrownError";
  sorted = lib.sort lib.lessThan; # definition order is module-system order
in
{
  test-kind-merge = {
    expr =
      let
        k = (eval [ more ]).kinds.box;
      in
      [
        (sorted k.below)
        (lib.attrNames k.spawns)
        k.size.name
      ];
    expected = [
      [
        "b"
        "c"
      ]
      [ "c" ]
      "int"
    ];
  };
  test-below-two-files-deduped = {
    expr = (eval [ { ren.kinds.box.below = [ "b" ]; } ]).kinds.box.below;
    expected = [ "b" ];
  };
  # negative control: the same field with a different type is a real clash
  test-kind-field-clash = {
    expr =
      (eval [
        more
        { ren.kinds.box.size = t.str; }
      ]).kinds.box.size;
    expectedError = err;
  };
  test-aspect-merge = {
    expr =
      let
        z = (eval [ more ]).aspects.z;
      in
      [
        z.at
        (lib.sort (a: b: a ? a) z.sys)
        (sorted z.excludes)
      ];
    expected = [
      "box"
      [
        { a = 1; }
        { b = 2; }
      ]
      [
        "x"
        "y"
      ]
    ];
  };
  # negative control: `at` given two different values conflicts (gen-merge `raw` in Ren)
  test-aspect-at-clash = {
    expr = (eval [ { ren.aspects.z.at = "other"; } ]).aspects.z.at;
    expectedError = err;
  };
  test-aspect-bare-class = {
    expr = (eval [ { ren.aspects.z.sys = final: prev: { }; } ]).aspects.z.sys;
    expectedError = err // {
      msg = "must be a `\\{ ... }: v` function";
    };
  };
}
