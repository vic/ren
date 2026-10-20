# e2e rows of the capability demos (#28 #31 #32 #60) that need realized config.
{
  o,
  lib,
  inputs,
}:
let
  web = o.checks.x86_64-linux.web;
  stage = o.nixosConfigurations.stage.config;
  noGui = o: o.checks.x86_64-linux.lb-no-gui;
  # #60 negative control: firefox on lb makes the lb-no-gui script exit 1 (evaluated, not built)
  gui =
    { ren, ... }:
    {
      ren.aspects.gui-on-lb = {
        at = ren.host.lb;
        nixos = { pkgs, ... }: { environment.systemPackages = [ pkgs.firefox ]; };
      };
    };
  withGui = inputs.impl.lib.mkFlake inputs {
    imports = [
      (inputs.import-tree ../modules)
      gui
    ];
  };
in
{
  # #60: the lb-no-gui check reads lb's realized systemPackages through `outputs`; it evaluates and passes
  test-check-no-gui-lb = {
    expr = [
      (lib.hasSuffix ".drv" (noGui o).drvPath)
      (noGui o).buildCommand
    ];
    expected = [
      true
      "touch $out"
    ];
  };
  # #60 negative: with firefox on lb the same check's build script exits 1
  test-check-no-gui-lb-firefox-fails = {
    expr = (noGui withGui).buildCommand;
    expected = "echo 'gui packages on lb: firefox'; exit 1";
  };
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
