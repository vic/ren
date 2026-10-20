{ ren, ... }:
let
  f = ren.fold;
  em = path: value: { inherit path value; };
  refused = x: (builtins.tryEval (builtins.deepSeq x null)).success;
in
{
  folds = {
    # list keeps scope traversal order (README.md#features: stage's users before its guest:ci), not id string order
    test-list-orders-by-path = {
      expr = f.list.apply "c" [
        (em "s/user:a" 1)
        (em "s/guest:ci" 2)
      ];
      expected = [
        1
        2
      ];
    };
    test-set-dedups = {
      expr = f.set.apply "c" [
        (em "a/b" 1)
        (em "a/a" 1)
        (em "a/c" 2)
      ];
      expected = [
        1
        2
      ];
    };
    test-attrs-merges-disjoint-nested = {
      expr = f.attrs.apply "c" [
        (em "a" { deploy.nodes.lb = 1; })
        (em "b" { deploy.nodes.web-1 = 2; })
      ];
      expected.deploy.nodes = {
        lb = 1;
        web-1 = 2;
      };
    };
    test-attrs-no-descend-one-sided = {
      expr = builtins.attrNames (
        f.attrs.apply "c" [
          (em "a" {
            big = {
              x = throw "forced";
            };
          })
          (em "b" { other = 1; })
        ]
      );
      expected = [
        "big"
        "other"
      ];
    };
    test-attrs-conflict-leaf-refused = {
      expr = refused (
        f.attrs.apply "c" [
          (em "a" { x.y = 1; })
          (em "b" { x.y = 2; })
        ]
      );
      expected = false;
    };
    test-attrs-equal-leaf-merges = {
      expr = f.attrs.apply "c" [
        (em "a" { agenix.url = "x"; })
        (em "b" { agenix.url = "x"; })
      ];
      expected.agenix.url = "x";
    };
    test-one-single = {
      expr = f.one.apply "c" [ (em "a" 7) ];
      expected = 7;
    };
    test-one-zero-refused = {
      expr = refused (f.one.apply "c" [ ]);
      expected = false;
    };
    test-one-two-refused = {
      expr = refused (
        f.one.apply "c" [
          (em "a" 1)
          (em "b" 2)
        ]
      );
      expected = false;
    };
  };
}
