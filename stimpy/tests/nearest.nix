# README.md#predicates `nearest K s`, `upTo K e` (Ren: ren/templates/ci/modules/lib/predicates-nearest.nix)
{ lib, stimpy }:
let
  p = stimpy.pred;
  mkScope = id: kinds: {
    __ren = {
      ref = "scope";
      kind = lib.head kinds;
      inst.__ren.id = "${id}i";
      inherit kinds id;
    };
  };
  r = mkScope "r" [ "root" ];
  b1 = mkScope "b1" [
    "box"
    "container"
  ];
  b2 = mkScope "b2" [
    "box"
    "container"
  ];
  i1 = mkScope "i1" [ "item" ];
  up = {
    r = [ ];
    b1 = [ r ];
    b2 = [ r ];
    i1 = [
      b1
      r
    ];
  };
  kids = {
    r = [
      b1
      b2
    ];
    b1 = [ i1 ];
    b2 = [ ];
    i1 = [ ];
  };
  ctx = {
    activeAt = _: _: false;
    children = s: kids.${s.__ren.id};
    ancestors = s: up.${s.__ren.id};
  };
  kind = k: {
    __ren = {
      ref = "kind";
      kind = k;
    };
  };
  near = k: s: ((stimpy.scoped ctx).nearest (kind k) s).__ren.id or null;
  m = q: s: p.match ctx q s;
in
{
  # superkind followed (box is container); ancestor-or-self
  test-nearest = {
    expr = [
      (near "container" i1)
      (near "box" b1)
      (near "root" i1)
    ];
    expected = [
      "b1i"
      "b1i"
      "ri"
    ];
  };
  # negative: no such ancestor is null
  test-nearest-none = {
    expr = near "box" r;
    expected = null;
  };
  # negative: a bare instance has no path
  test-nearest-instance-throws = {
    expr = (stimpy.scoped ctx).nearest (kind "box") { __ren.ref = "inst"; };
    expectedError.type = "ThrownError";
  };
  test-upTo = {
    expr = [
      (m (stimpy.upTo (kind "box") i1) b1)
      (m (stimpy.upTo (kind "box") b1) b1)
      (m (stimpy.upTo (kind "box") i1) b2)
      (m (stimpy.upTo (kind "box") i1) i1)
    ];
    expected = [
      true
      true
      false
      false
    ];
  };
}
