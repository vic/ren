# README.md#kinds: `below` may form a cycle (recursive kinds); an instance appears at most once on a path
{ lib, stimpy }:
let
  ev = m: (stimpy.evalFleet { } m).scopes;
  cycle =
    { ren, ... }:
    {
      ren.kinds = {
        r.below = [ ren.kinds.c1 ];
        c1 = {
          below = [ ren.kinds.c2 ];
          spawns.c2 = s: if s.c1.name == "a" then ren.c2 else { };
        };
        c2 = {
          below = [ ren.kinds.c1 ];
          spawns.c1 = _: lib.filterAttrs (n: _: n == "b") ren.c1;
        };
      };
      ren.r.y = { };
      ren.c1.a = { };
      ren.c1.b = { };
      ren.c2.x = { };
    };
  twice =
    { ren, ... }:
    {
      ren.kinds.r.below = [ ren.kinds.a ];
      ren.kinds.a.below = [ ren.kinds.a ];
      ren.r.y = { };
      ren.a.x = { };
    };
in
{
  test-below-cycle-nested-ids = {
    expr = lib.attrNames (ev cycle);
    expected = [
      "r:y"
      "r:y/c1:a"
      "r:y/c1:a/c2:x"
      "r:y/c1:a/c2:x/c1:b"
      "r:y/c1:b"
    ];
  };
  test-twice-on-path = {
    expr = lib.attrNames (ev twice);
    expectedError.type = "ThrownError";
    expectedError.msg = "ren: instance a:x twice on path r:y/a:x/a:x";
  };
}
