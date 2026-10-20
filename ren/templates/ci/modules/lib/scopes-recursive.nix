# README.md#kinds: `below` may form a cycle (recursive kinds); an instance appears at most once on a path.
# The twice-on-path refusal is `scopes.test-twice-on-path` (scopes.nix).
{ ren, lib }:
let
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
in
{
  scopes.test-below-cycle-nested-ids = {
    expr = builtins.attrNames (ren.evalFleet { nixpkgs = { inherit lib; }; } cycle).scopes;
    expected = [
      "r:y"
      "r:y/c1:a"
      "r:y/c1:a/c2:x"
      "r:y/c1:a/c2:x/c1:b"
      "r:y/c1:b"
    ];
  };
}
