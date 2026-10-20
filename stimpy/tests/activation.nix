{ lib, stimpy }:
let
  inherit (import ./_vocab.nix { inherit lib stimpy; })
    run
    err
    z1
    n1
    n2
    v1
    p1
    p2
    pv
    ;
  act = f: (run [ ({ ren, ... }: { ren.aspects = f ren; }) ]).active;
in
{
  test-at-kind-and-subkind = {
    expr =
      (act (ren: {
        a.at = ren.kinds.node;
      })).a;
    expected = [
      n1
      n2
      v1
    ];
  };
  # README.md#kinds no `at` ⟹ inactive unless included
  test-no-at = {
    expr =
      (act (_: {
        a = { };
      })).a;
    expected = [ ];
  };
  test-includes-subtree = {
    expr =
      (act (ren: {
        a = { };
        i = {
          at = ren.zone.z1;
          includes = [ ren.aspects.a ];
        };
      })).a;
    expected = [
      z1
      n1
      p1
      n2
      p2
    ];
  };
  test-excludes-wins = {
    expr =
      (act (ren: {
        a.at = ren.kinds.node;
        x = {
          at = ren.node.n2;
          excludes = [ ren.aspects.a ];
        };
      })).a;
    expected = [
      n1
      v1
    ];
  };
  # README.md#channels within = proper ancestor
  test-within-proper = {
    expr =
      (act (ren: {
        a.at = ren.lib.within ren.kinds.node;
      })).a;
    expected = [
      p1
      p2
      pv
    ];
  };
  test-aspect-ref = {
    expr =
      (act (ren: {
        a.at = ren.node.n1;
        b.at = ren.lib.and [
          ren.kinds.node
          (ren.lib.not ren.aspects.a)
        ];
      })).b;
    expected = [
      n2
      v1
    ];
  };
  # positive cycle = least fixpoint
  test-positive-cycle = {
    expr =
      let
        r = act (ren: {
          x = {
            at = ren.node.n1;
            includes = [ ren.aspects.y ];
          };
          y.includes = [ ren.aspects.x ];
          z.at = ren.lib.and [
            ren.aspects.z
            ren.kinds.node
          ];
        });
      in
      [
        r.y
        r.z
      ];
    expected = [
      [
        n1
        p1
      ]
      [ ]
    ];
  };
  test-not-stratified = {
    expr =
      (act (ren: {
        s1.at = ren.lib.not ren.aspects.s2;
        s2.at = ren.aspects.s1;
      })).s1;
    expectedError = err;
  };
  test-self-exclude = {
    expr =
      (act (ren: {
        s.at = ren.kinds.node;
        s.excludes = [ ren.aspects.s ];
      })).s;
    expectedError = err;
  };
}
