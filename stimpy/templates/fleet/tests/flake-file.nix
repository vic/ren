# fleet.md v35: flake-file is a class at the root, fed by the `flake-inputs` channel `into`.
{ ev, r, ... }:
let
  i = import ./_ids.nix;
in
{
  # row: a class key in a channel `into` forwards to the class's branch (the root)
  test-flake-file-class-at-root = {
    expr = r.branches.flake-file;
    expected.${i.root} = 0;
  };
  # row: content forwarded from a channel `into` lands (agenix from secrets)
  test-flake-file-forwarded-lands = {
    expr = r.outputs.flake-file.inputs.agenix.url;
    expected = "github:ryantm/agenix";
  };
  # flake-file is a class: an aspect's flake-file content merges with the forwarded inputs
  test-flake-file-aspect-content = {
    expr =
      builtins.attrNames
        (ev (
          { ren, ... }:
          {
            ren.aspects.extra-input = {
              at = ren.fleet.main;
              flake-file.inputs.extra.url = "github:x/extra";
            };
          }
        )).outputs.flake-file.inputs;
    expected = [
      "agenix"
      "extra"
      "microvm"
    ];
  };
}
