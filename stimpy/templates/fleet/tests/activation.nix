{ lib, r, ... }:
let
  i = import ./_ids.nix;
  has = a: id: lib.elem id (r.active.${a} or [ ]);
  sorted = lib.sort lib.lessThan;
in
{
  # row: contains
  test-docker-active = {
    expr = r.active.docker;
    expected = [
      i.stage
      i.ci
    ];
  };
  # row: host-qualified
  test-htop-only-alice-web1 = {
    expr = r.active.htop;
    expected = [ (i.user i.web1 "alice") ];
  };
  # row: standalone home (ssh-agent not within machine)
  test-ssh-agent-not-standalone = {
    expr = lib.filter (id: lib.hasPrefix i.laptop id || lib.hasPrefix i.pixel id) r.active.ssh-agent;
    expected = [ ];
  };
  test-ssh-agent-on-machine-users = {
    expr = lib.length r.active.ssh-agent;
    expected = 9; # users under machines (not pixel, not alice-laptop)
  };
  # row: darwin + os: no kernel / impermanence on studio
  test-kernel-not-on-studio = {
    expr = has "kernel" i.studio;
    expected = false;
  };
  test-impermanence-metal-only = {
    expr = sorted r.active.impermanence;
    expected = sorted i.metals;
  };
  test-dock-studio-only = {
    expr = r.active.dock;
    expected = [ i.studio ];
  };
  # row: ren kinds guest / vm
  test-vm-ci-only = {
    expr = r.active.vm;
    expected = [ i.ci ];
  };
  test-vm-host-stage-only = {
    expr = r.active.vm-host;
    expected = [ i.stage ];
  };
  test-secrets-hosts-not-studio = {
    expr = sorted r.active.secrets;
    expected = sorted (i.metals ++ [ i.ci ]);
  };
  # row: substitute / activators
  test-quiet-web2 = {
    expr = r.active.quiet;
    expected = [ i.web2 ];
  };
  test-lb-activator = {
    expr = r.active.lb;
    expected = [ i.lb ];
  };
  test-web-activator = {
    expr = r.active.web;
    expected = [
      i.web1
      i.web2
      i.stage
    ];
  };
  # an aspect ref in a predicate = "active here".
  # nginx is included at stage, so it is active in stage's subtree (README.md#classes),
  # and ci matches ren.kinds.host through guest `is = host` (README.md#vocabulary)
  test-http-port-follows-nginx = {
    expr = r.active.http-port;
    expected = [
      i.web1
      i.web2
      i.stage
      i.ci
    ];
  };
  test-desktop-stage = {
    expr = r.active.desktop;
    expected = [ i.stage ];
  };
  # row: per-system
  test-tools-three-systems = {
    expr = sorted r.active.tools;
    expected = sorted (
      map i.sys [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ]
    );
  };
  test-dns-prod = {
    expr = r.active.dns;
    expected = [ i.prod ];
  };
  test-replica-scrape = {
    expr = r.active.replica-scrape;
    expected = [ i.replica ];
  };
  test-base-every-machine = {
    expr = sorted r.active.base;
    expected = sorted i.machines;
  };
  # row: hmPlatforms - tiling is active on every user, but lands only under mac (see collect.nix)
  test-sync-every-user = {
    expr = lib.length r.active.sync;
    expected = 11;
  };
  # UNTESTABLE-T1: is P x on the path (stage users' syncthing tray) - needs forced homeManager content
  # UNTESTABLE-T1: stratum-1 'not stratified' error - lib tests, no template fixture has the cycle
}
