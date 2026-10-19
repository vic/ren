# e2e rows of the capability demos (#28 #31 #32) that need realized config.
{ o, lib }:
let
  web = o.checks.x86_64-linux.web;
  stage = o.nixosConfigurations.stage.config;
in
{
  # #31: web-1 from _inventory.json keeps its settings (kernel = latest; see test-kernel-latest)
  test-inventory-web-1-built = {
    expr = o.nixosConfigurations.web-1.config.networking.hostName;
    expected = "web-1";
  };
  # #28: the plan is plain data in the flake outputs
  test-vars-plan = {
    expr = builtins.attrNames o.vars.per-machine ++ builtins.attrNames o.vars.shared;
    expected = [
      "lb"
      "stage"
      "web-1"
      "web-2"
      "ca"
    ];
  };
  # #32: checks.x86_64-linux.web is a nixosTest over two nodes (evaluated, not run)
  test-checks-web-nodes = {
    expr = [
      web.type
      (builtins.attrNames web.nodes)
      web.config.nodes.web.services.nginx.enable
    ];
    expected = [
      "derivation"
      [
        "client"
        "web"
      ]
      true
    ];
  };
  # #32: no ./facter/<host>.json in the template, so no report is set (edge nixpkgs has the option)
  test-facter-no-report = {
    expr = stage.hardware.facter.reportPath;
    expected = null;
  };
}
