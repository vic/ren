# Instances as data: `ren.lib.data inst` gives the kind's fields alone (#23); module-system
# names and instance internals are refused as field names at kind declaration (#22).
{ lib, ev, ... }:
let
  i = import ./_ids.nix;
  t = lib.types;
  # a data kind `vim` with field `f` (no `below` lists it: no scopes); probe reads `g ren` back
  probe =
    f: g:
    (ev (
      { ren, ... }:
      {
        ren.kinds.vim = {
          features = t.listOf t.str;
          ${f} = t.str;
        };
        ren.vim.full = {
          features = [ "a" ];
          ${f} = "k2";
        };
        ren.aspects.probe = {
          at = ren.fleet.main;
          flake-inputs = { ... }: { probe = g ren; };
        };
      }
    )).pools.flake-inputs.${i.root}.probe;
  # a module option typed with the kind's fields, set from a value
  intoOption =
    v:
    (lib.evalModules {
      modules = [
        {
          options.vim = lib.mkOption {
            type = t.submodule {
              options.features = lib.mkOption { type = t.listOf t.str; };
              options.sk = lib.mkOption { type = t.str; };
            };
          };
          config.vim = v;
        }
      ];
    }).config.vim;
  thrown = expr: {
    inherit expr;
    expectedError.type = "ThrownError";
  };
in
{
  # control: a non-reserved field reads back
  test-field-sk-reads = {
    expr = probe "sk" (ren: ren.vim.full.sk);
    expected = "k2";
  };
  # #22: `key` is a module key (gen-merge, nixpkgs): refused at kind declaration
  test-field-key-refused = thrown (probe "key" (ren: ren.vim.full.features));
  # #22: an instance internal is refused too
  test-field-kind-refused = thrown (probe "kind" (ren: ren.vim.full.features));
  # #23: the fields alone pass into a module option
  test-data-into-option = {
    expr = probe "sk" (ren: intoOption (ren.lib.data ren.vim.full));
    expected = {
      features = [ "a" ];
      sk = "k2";
    };
  };
  # #23 control: the instance itself carries internals, which the option refuses
  test-instance-into-option-throws = thrown (probe "sk" (ren: intoOption ren.vim.full));
}
