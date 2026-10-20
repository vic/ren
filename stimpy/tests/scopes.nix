{ lib, stimpy }:
let
  inherit (import ./_vocab.nix { inherit lib stimpy; })
    run
    err
    w
    z1
    z2
    n1
    n2
    v1
    p1
    p2
    pv
    ;
  ids = ms: (run ms).scopes;
  kind = m: { ren.kinds = m; };
in
{
  test-scope-order = {
    expr = lib.attrNames (ids [ ]) == lib.sort lib.lessThan (lib.attrNames (ids [ ]));
    expected = true;
  };
  test-scope-ids = {
    expr = lib.attrNames (ids [ ]);
    expected = lib.sort lib.lessThan [
      w
      z1
      z2
      n1
      n2
      v1
      p1
      p2
      pv
    ];
  };
  # README.md#scopes: vm binds under vm and its superkind node; parent; __ren.scope
  test-bindings-superkind = {
    expr =
      let
        s = (ids [ ]).${pv};
      in
      [
        s.node.name
        s.vm.name
        s.parent.name
        s.zone.name
        s.node.__ren.scope.__ren.id
      ];
    expected = [
      "v1"
      "v1"
      "v1"
      "z2"
      v1
    ];
  };
  test-spawns-ok = {
    expr = ids [ ({ ren, ... }: kind { top.below = [ ren.kinds.person ]; }) ] ? "world:w";
    expected = true;
  };
  test-spawns-not-in-below = {
    expr = ids [
      (
        { ren, ... }:
        kind {
          top.below = [ ren.kinds.person ];
          top.spawns.node = _: { };
        }
      )
    ];
    expectedError = err;
  };
  # guest-in-guest analogue: vm's own below lacks vm ⟹ no vm under vm
  test-no-vm-in-vm = {
    expr = lib.any (lib.hasInfix "vm:v1/vm:") (lib.attrNames (ids [ ]));
    expected = false;
  };
  test-exact-kind-spawn = {
    expr = ids [
      (
        { ren, ... }:
        {
          ren.kinds.top = {
            below = [ ren.kinds.node ];
            spawns.node = _: ren.vm;
          };
          ren.top.t = { };
        }
      )
    ];
    expectedError = err;
  };
  test-duplicate-instance-name = {
    expr = ids [ ({ ren, ... }: { ren.vm.n1.zone = ren.zone.z1; }) ];
    expectedError = err;
  };
  # function kind: arg fields bound, guard filters
  test-function-kind =
    let
      r = ids [
        (
          { ren, ... }:
          {
            ren.kinds.hub.below = [ ren.kinds.link ];
            ren.hub.h = { };
            ren.kinds.link = { zone }: ren.lib.when (s: s.zone.name == "z1") { };
            ren.link.a.zone = ren.zone.z1;
            ren.link.b.zone = ren.zone.z2;
          }
        )
      ];
    in
    {
      expr = [
        (r ? "hub:h/link:a")
        (r ? "hub:h/link:b")
        r."hub:h/link:a".zone.name
      ];
      expected = [
        true
        false
        "z1"
      ];
    };
}
