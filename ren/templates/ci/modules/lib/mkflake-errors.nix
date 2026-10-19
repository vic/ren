{ ren, lib }:
let
  inherit (import ../../fixtures/mkflake.nix { inherit ren lib; }) run inputs;
  # mini fleet: class `sys` at box emits channel `note` (at = zone) from a box scope
  mini =
    { ren, ... }:
    {
      ren.classes.sys = {
        at = ren.kinds.box;
        into = _: _: { note = 1; };
      };
      ren.kinds = {
        root.below = [ ren.kinds.box ];
        box = { };
      };
      ren.root.r = { };
      ren.box.b = { };
      ren.channels.note = {
        fold = ren.lib.fold.list;
        at = ren.kinds.root;
        to = _: ren.kinds.root;
        into = _: pool: { note = pool; };
      };
      ren.aspects.a = {
        at = ren.kinds.box;
        sys = { };
      };
    };
in
{
  mkflake-errors = {
    test-unknown-key-inactive-aspect = {
      expr =
        (run (_: {
          ghost.bogus = 1;
        })).systems;
      expectedError.type = "ThrownError";
      expectedError.msg = "neither class nor channel";
    };
    test-into-channel-outside-at = {
      expr = (ren.mkFlake inputs mini).note or null;
      expectedError.type = "ThrownError";
      expectedError.msg = "emits channel `note` outside its `at`";
    };
    # branches are disjoint (fleet.md:94): two branches matching one scope is refused
    test-overlapping-branches = {
      expr =
        (ren.mkFlake inputs (
          { ren, ... }: {
            imports = [ mini ];
            ren.classes.out = [
              {
                at = ren.kinds.box;
                into = _: _: { };
              }
              {
                at = ren.kinds.box;
                into = _: _: { };
              }
            ];
            ren.aspects.o = {
              at = ren.kinds.box;
              out = { };
            };
          }
        )).out;
      expectedError.type = "ThrownError";
      expectedError.msg = "has 2 contributors";
    };
  };
}
