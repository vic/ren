# README.md#scopes: a scope binds the arg fields of a function kind; building scopes forces no other field.
# (Ren: ren/templates/ci/modules/lib/scopes-lazy.nix)
{ lib, stimpy }:
let
  res = stimpy.evalFleet { } (
    { ren, lib, ... }:
    {
      ren.kinds = {
        root.below = [ ren.kinds.box ];
        tag = { };
        box =
          { tag }:
          {
            slow = lib.types.raw;
            on = ren.kinds.tag;
          };
      };
      ren.root.r = { };
      ren.tag.x = { };
      ren.box.b = {
        tag = ren.tag.x;
        on = ren.tag.x;
        slow = throw "no";
      };
    }
  );
  s = res.scopes."root:r/box:b";
in
{
  test-scope-forces-no-field = {
    expr = [
      (builtins.elem "slow" (builtins.attrNames s))
      s.tag.name
      (s ? on)
    ];
    expected = [
      false
      "x"
      false
    ];
  };
}
