# Shared template helpers live in `ren.helpers.<name>`, never in `_module.args` (owner rule).
{ ev, ... }:
let
  i = import ./_ids.nix;
  names = [
    "metal"
    "pkgsOf"
    "usersOn"
    "settingsT"
  ];
  probe =
    (ev (
      { ren, config, ... }:
      {
        ren.aspects.probe = {
          at = ren.fleet.main;
          flake-inputs =
            { lib, ... }:
            {
              probe = {
                helpers = builtins.filter (n: ren.helpers ? ${n}) names;
                args = builtins.filter (n: config._module.args ? ${n}) names;
                opt = (ren.lib.opt lib.types.bool false).default;
                maybe = (ren.lib.maybe lib.types.str).default;
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
  # README.md#helpers: option shorthands ship in `ren.lib` (`maybe t` = `opt (nullOr t) null`)
  test-opt-maybe-in-ren-lib = {
    expr = [
      probe.opt
      probe.maybe
    ];
    expected = [
      false
      null
    ];
  };
}
