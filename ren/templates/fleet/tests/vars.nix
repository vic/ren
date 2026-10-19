# #28: services declare generated values; the fleet emits one plan `vars` (shared vs per-machine).
{ lib, r, ... }:
let
  names = builtins.attrNames;
in
{
  # row: one plan, two sections
  test-vars-sections = {
    expr = names r.outputs.vars;
    expected = [
      "per-machine"
      "shared"
    ];
  };
  # row: the root declaration is shared
  test-vars-shared-ca = {
    expr = r.outputs.vars.shared;
    expected.ca.files = [
      "ca.crt"
      "ca.key"
    ];
  };
  # row: deploy-record declares a deploy key per metal host; none for ci or studio
  test-vars-per-machine-metal = {
    expr = lib.mapAttrs (_: g: names g) r.outputs.vars.per-machine;
    expected = lib.genAttrs [ "lb" "stage" "web-1" "web-2" ] (_: [ "deploy-key" ]);
  };
}
