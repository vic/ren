# Entry points (issue #33): one tiny fleet through each way in; each asserts the same output key.
{ lib, stimpy }:
let
  inputs = { };
  mod =
    { ren, ... }:
    {
      ren.classes.probe = {
        at = ren.kinds.box;
        into = { box, ... }: _: { probed.${box.name} = true; };
      };
      ren.kinds = {
        root.below = [ ren.kinds.box ];
        box = { };
      };
      ren.root.r = { };
      ren.box.b = { };
      ren.aspects.a = {
        at = ren.kinds.box;
        probe = { };
      };
    };
  keys = o: builtins.attrNames o.probed;
  want = [ "b" ];
  # noflake: plain `import` with the lib from the lock, no flake anywhere
  plain = import ../. { lib = import "${(import ../lock.nix).nixpkgs}/lib"; };
  hosted =
    (lib.evalModules {
      modules = [
        stimpy.flakeModule
        { options.flake = lib.mkOption { type = lib.types.raw; }; }
        {
          _module.args = { inherit inputs; };
          fleet = mod;
        }
      ];
    }).config.flake;
in
{
  test-entry-flakes = {
    expr = keys (stimpy.mkFlake inputs mod);
    expected = want;
  };
  test-entry-noflake = {
    expr = keys (plain.mkFlake inputs mod);
    expected = want;
  };
  # flake-parts is not locked: call its module function with a fake `config`
  test-entry-flake-parts = {
    expr =
      keys
        (stimpy.flakeModule {
          inherit lib inputs;
          config.fleet = mod;
        }).config.flake;
    expected = want;
  };
  test-entry-evalmodules = {
    expr = keys hosted;
    expected = want;
  };
}
