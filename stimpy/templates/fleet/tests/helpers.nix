# Shared template helpers live in `ren.helpers.<name>`, never in `_module.args` (owner rule).
{ ev, ... }:
let
  i = import ./_ids.nix;
  names = [
    "metal"
    "pkgsOf"
    "usersOn"
    "settingsT"
    "opt"
    "maybe"
  ];
  probe =
    (ev (
      { ren, config, ... }:
      {
        ren.aspects.probe = {
          at = ren.fleet.main;
          flake-inputs =
            { ... }:
            {
              probe = {
                helpers = builtins.filter (n: ren.helpers ? ${n}) names;
                args = builtins.filter (n: config._module.args ? ${n}) names;
              };
            };
        };
      }
    )).pools.flake-inputs.${i.root}.probe;
in
{
  # row: every shared helper is published in `ren.helpers`
  test-helpers-in-ren-helpers = {
    expr = probe.helpers;
    expected = names;
  };
  # row: no template helper is a module arg
  test-helpers-not-module-args = {
    expr = probe.args;
    expected = [ ];
  };
}
