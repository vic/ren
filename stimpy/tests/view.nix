{ lib, stimpy }:
let
  t = lib.types;
  inherit (stimpy) view;
  renLib.when = f: {
    __ren = {
      op = "when";
      inherit f;
    };
    __functor = self: fields: fields // { __guard = self; };
  };
  vocab =
    { ren, ... }:
    {
      ren.kinds = {
        shelf = {
          label = t.str;
          size = lib.mkOption {
            type = t.int;
            default = 3;
          };
        };
        box = {
          shelf = ren.kinds.shelf;
          peer = t.nullOr ren.kinds.box;
        };
        crate = {
          is = ren.kinds.box;
          lid = t.bool;
        };
        tag.parents = t.listOf ren.kinds.tag;
        pair = { shelf, box }: ren.lib.when (_: true) { note = t.str; };
      };
      ren.shelf.s1.label = "a";
      ren.shelf.s2.label = "b";
      ren.box.b1 = {
        shelf = ren.shelf.s1;
        peer = null;
      };
    };
  eval =
    ms:
    (lib.evalModules {
      modules = [
        view.module
        { _module.args.renLib = renLib; }
        vocab
      ]
      ++ ms;
    })._module.args.ren;
  # crate instance named n under kind-family box; also points b1.peer at it
  one =
    n:
    { ren, ... }:
    {
      ren.box.b1.peer = lib.mkForce ren.crate.${n};
      ren.crate.${n} = {
        shelf = ren.shelf.s2;
        peer = null;
        lid = true;
      };
    };
  tags =
    { ren, ... }:
    {
      ren.tag.a.parents = [ ren.tag.b ];
      ren.tag.b.parents = [ ];
    };
  cyc =
    { ren, ... }:
    {
      ren.box.x = {
        shelf = ren.shelf.s1;
        peer = ren.box.y;
      };
      ren.box.y = {
        shelf = ren.shelf.s1;
        peer = ren.box.x;
      };
    };
  pair =
    b:
    { ren, ... }:
    {
      ren.pair.p = {
        shelf = ren.shelf.s1;
        box = ren.${b}.${if b == "box" then "b1" else "s1"};
        note = "n";
      };
    };
  checks = r: lib.all lib.id r.__ren.checks;
  err.type = "ThrownError";
in
{
  test-required-missing = {
    expr = (eval [ { ren.shelf.s3 = { }; } ]).shelf.s3.label;
    expectedError = err;
  };
  test-default = {
    expr = (eval [ ]).shelf.s1.size;
    expected = 3;
  };
  test-ref-ok = {
    expr = (eval [ ]).box.b1.shelf.__ren.id;
    expected = "shelf/s1";
  };
  test-ref-wrong-kind = {
    expr = (eval [ ({ ren, ... }: { ren.box.b1.peer = lib.mkForce ren.shelf.s1; }) ]).box.b1.peer;
    expectedError = err;
  };
  # subkind instance where superkind ref expected + `is` field union
  test-subkind-and-is-union =
    let
      c = (eval [ (one "c1") ]).box.b1.peer;
    in
    {
      expr = [
        c.__ren.id
        c.lid
        c.shelf.label
      ];
      expected = [
        "box/c1"
        true
        "b"
      ];
    };
  test-self-ref-kind = {
    expr = map (p: p.name) (eval [ tags ]).tag.a.parents;
    expected = [ "b" ];
  };
  test-cyclic-refs-same-id =
    let
      r = eval [ cyc ];
    in
    {
      expr = [
        r.box.x.peer.peer.name
        (r.box.x.peer.peer.__ren.id == r.box.x.__ren.id)
      ];
      expected = [
        "x"
        true
      ];
    };
  test-checks-pass = {
    expr = checks (eval [ cyc ]);
    expected = true;
  };
  test-duplicate-name-in-family = {
    expr = checks (eval [ (one "b1") ]);
    expectedError = err;
  };
  test-reserved-field = {
    expr = checks (eval [ { ren.kinds.bad.name = t.str; } ]);
    expectedError = err;
  };
  test-reserved-field-pkgs = {
    expr = checks (eval [ { ren.kinds.bad.pkgs = t.str; } ]);
    expectedError = err;
  };
  test-unknown-kind = {
    expr = (eval [ { ren.foo.x = { }; } ]).foo.x;
    expectedError = err;
  };
  test-function-kind-typed =
    let
      r = eval [ (pair "box") ];
    in
    {
      expr = [
        r.pair.p.shelf.name
        r.pair.p.note
        (r.__ren.guard "pair").__ren.op
      ];
      expected = [
        "s1"
        "n"
        "when"
      ];
    };
  test-function-kind-wrong-kind = {
    expr = (eval [ (pair "shelf") ]).pair.p.box;
    expectedError = err;
  };
  test-ref-conflict = {
    expr =
      (eval [
        (
          { ren, ... }:
          {
            ren.box.b1.shelf = ren.shelf.s2;
          }
        )
      ]).box.b1.shelf;
    expectedError = err;
  };
}
