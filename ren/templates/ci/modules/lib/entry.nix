# Entry points (issue #33): one tiny fleet through each way in; each asserts the same output key.
{ ren, lib }:
let
  inherit (import ../../fixtures/mkflake.nix { inherit ren lib; }) fleet inputs;
  mod = fleet (_: { });
  keys = o: builtins.attrNames o.systems;
  want = [
    "b1"
    "b2"
    "b3"
  ];
  # noflake: plain `import`, gen from the lock (with-inputs), no flake anywhere
  plain = import ../../../.. { gen = import (import ../../with-inputs.nix { }).gen.outPath { }; };
  # Gen's evalModules hosts the fleet as an option (Ren has no nixpkgs, so this is also the plain-evalModules case)
  hosted =
    (lib.evalModules {
      modules = [
        ren.flakeModule
        { options.flake = lib.mkOption { type = lib.types.raw; }; }
        {
          _module.args = { inherit inputs; };
          fleet = mod;
        }
      ];
    }).config.flake;
in
{
  entry = {
    test-flakes = {
      expr = keys (ren.mkFlake inputs mod);
      expected = want;
    };
    test-noflake = {
      expr = keys (plain.mkFlake inputs mod);
      expected = want;
    };
    # flake-parts is not locked: call its module function with a fake `config`
    test-flake-parts = {
      expr =
        keys
          (ren.flakeModule {
            inherit lib inputs;
            config.fleet = mod;
          }).config.flake;
      expected = want;
    };
    test-evalmodules-gen = {
      expr = keys hosted;
      expected = want;
    };
  };
}
