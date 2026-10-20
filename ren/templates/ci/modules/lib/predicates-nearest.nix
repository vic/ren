{ ren, lib }:
let
  inherit (import ../../fixtures/predicates.nix { inherit ren lib; })
    ctx
    sc
    t
    ids
    hostK
    kind
    ;
  at = n: sc.scopes.${ids.${n}};
  near = K: n: (ren.nearestAt ctx { } K (at n)).__id or null;
in
{
  predicates = {
    # README.md#predicates `nearest K s`: ancestor-or-self instance of kind K, following `is`
    test-nearest = {
      expr = [
        (near hostK "user")
        (near hostK "host")
        (near hostK "guest")
        (near (kind "machine") "guest")
        (near (kind "env") "user")
      ];
      expected = [
        "machine:h"
        "machine:h"
        "machine:g"
        "machine:g"
        "env:e"
      ];
    };
    # negative: no such ancestor is null
    test-nearest-none = {
      expr = near hostK "root";
      expected = null;
    };
    # negative: a bare instance has no path
    test-nearest-instance-throws = {
      expr = ren.nearestAt ctx { } hostK { __ren = "instance"; };
      expectedError.type = "ThrownError";
    };
    # README.md#predicates `upTo K e`: e itself if a K, else the K above it
    test-upTo = {
      expr = [
        (t (ren.upTo hostK (at "user")) "host")
        (t (ren.upTo hostK (at "host")) "host")
        (t (ren.upTo hostK (at "user")) "host2")
        (t (ren.upTo hostK (at "user")) "user")
      ];
      expected = [
        true
        true
        false
        false
      ];
    };
  };
}
