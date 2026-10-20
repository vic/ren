# #48: the `docs` output is a mermaid map built from `ren.lib.result` (scopes and forwards).
{ lib, r, ... }:
let
  i = import ./_ids.nix;
  node = id: "s${builtins.hashString "md5" id}"; # the handle docs.nix gives a scope id
  has = lib.hasInfix;
in
{
  test-docs-has-scope = {
    expr = has "${node i.ci}[\"${i.ci}\"]" r.outputs.docs.mermaid;
    expected = true;
  };
  # guest ci forwards its nixos module into host stage
  test-docs-has-forward = {
    expr = has "${node i.ci} -->|nixos| ${node i.stage}" r.outputs.docs.mermaid;
    expected = true;
  };
  test-result-forwards-ci = {
    expr = lib.elem {
      class = "nixos";
      from = i.ci;
      to = i.stage;
    } r.forwards;
    expected = true;
  };
}
