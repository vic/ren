{ lib, r, ... }:
let
  i = import ./_ids.nix;
  sorted = lib.sort lib.lessThan;
  names = builtins.attrNames;
  has = l: x: lib.elem x l;
in
{
  # ── emitted ──
  test-emitted-overlays-root = {
    expr = r.emitted.overlays;
    expected = [ i.root ];
  };
  test-emitted-deployment-metal = {
    expr = sorted r.emitted.deployment;
    expected = sorted i.metals;
  };
  # nginx active in stage's subtree (fleet.md:102); ci is a host via `is` (fleet.md:91)
  test-emitted-backends-nginx-hosts = {
    expr = sorted r.emitted.backends;
    expected = sorted [
      i.web1
      i.web2
      i.stage
      i.ci
    ];
  };
  # row: flake-file - only active aspects emit (secrets on hosts, vm on ci)
  test-emitted-flake-inputs-only-active = {
    expr = sorted (lib.unique r.emitted."flake-inputs");
    expected = sorted (i.metals ++ [ i.ci ]);
  };
  test-emitted-flake-inputs-not-studio = {
    expr = has r.emitted."flake-inputs" i.studio;
    expected = false;
  };
  test-emitted-packages-systems = {
    expr = sorted r.emitted.packages;
    expected = sorted (
      map i.sys [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ]
    );
  };
  # C1: persist emitters = hosts + users within a host
  test-emitted-persist-no-mac-phone-home-users = {
    expr = lib.filter (
      id: lib.hasInfix "mac:" id || lib.hasInfix "phone:" id || lib.hasInfix "home:" id
    ) r.emitted.persist;
    expected = [ ];
  };
  test-emitted-persist-host-users = {
    expr = has r.emitted.persist (i.user i.ci "bob");
    expected = true;
  };
  test-emitted-scrape-replica = {
    expr = r.emitted.scrape;
    expected = [ i.replica ];
  };

  # ── outputs (key names only; leaves stay lazy) ──
  # row: darwin + os: studio in darwinConfigurations, never in nixos/colmena
  test-outputs-darwin = {
    expr = names r.outputs.darwinConfigurations;
    expected = [ "studio" ];
  };
  test-outputs-nixos-no-studio-no-ci = {
    expr = names r.outputs.nixosConfigurations;
    expected = [
      "lb"
      "stage"
      "web-1"
      "web-2"
    ];
  };
  # `colmena` is a channel (fleet.md:306); its `into` writes `colmenaHive`, which forces
  # inputs.colmena (unfetched in Tier 1). The node names live in the root pool.
  test-outputs-colmena-nodes = {
    expr = names r.pools.colmena.${i.root};
    expected = [
      "lb"
      "stage"
      "web-1"
      "web-2"
    ];
  };
  # row: recursive attrs - deploy.nodes from four host scopes, no top-level conflict
  test-outputs-deploy-nodes = {
    expr = names r.outputs.deploy.nodes;
    expected = [
      "lb"
      "stage"
      "web-1"
      "web-2"
    ];
  };
  # row: standalone home
  test-outputs-homes = {
    expr = names r.outputs.homeConfigurations;
    expected = [ "alice-laptop" ];
  };
  test-outputs-droid = {
    expr = names r.outputs.nixOnDroidConfigurations;
    expected = [ "pixel" ];
  };
  # row: per-system (never keyed by host)
  test-outputs-packages-systems = {
    expr = names r.outputs.packages;
    expected = [
      "aarch64-darwin"
      "aarch64-linux"
      "x86_64-linux"
    ];
  };
  test-outputs-terraform-prod-edge-only = {
    expr = names r.outputs.terraformConfigurations;
    expected = [ "dns" ];
  };
  # the output name is fixed, so only `landed` shows that staging (edge = false) writes no dns
  test-landed-terraform-prod-only = {
    expr = names r.landed.terraform;
    expected = [ i.prod ];
  };
  # row: flake-file option beside nixosConfigurations
  test-outputs-flake-file-inputs = {
    expr = names r.outputs.flake-file.inputs;
    expected = [
      "agenix"
      "microvm"
    ];
  };

  # ── landed ──
  # row: substitute
  test-landed-os-web2-short = {
    expr = [
      (has r.landed.os.${i.web2} "motd-short")
      (has r.landed.os.${i.web2} "motd")
    ];
    expected = [
      true
      false
    ];
  };
  test-landed-os-others-motd = {
    expr =
      map
        (m: [
          (has r.landed.os.${m} "motd")
          (has r.landed.os.${m} "motd-short")
        ])
        [
          i.lb
          i.web1
          i.stage
          i.ci
          i.studio
        ];
    expected = lib.genList (_: [
      true
      false
    ]) 5;
  };
  # row: hmPlatforms (homeDarwin): aerospace only for studio users
  test-landed-homedarwin-studio-users = {
    expr = names r.landed.homeDarwin;
    expected = sorted [
      (i.user i.studio "alice")
      (i.user i.studio "bob")
    ];
  };
  test-landed-homedarwin-tiling = {
    expr = r.landed.homeDarwin.${i.user i.studio "alice"};
    expected = [ "tiling" ];
  };
  # row: host-qualified
  test-landed-hm-htop-web1-only = {
    expr = map (id: has (r.landed.homeManager.${id} or [ ]) "htop") [
      (i.user i.web1 "alice")
      (i.user i.lb "alice")
      (i.user i.web2 "alice")
      (i.user i.stage "bob")
    ];
    expected = [
      true
      false
      false
      false
    ];
  };
  # row: standalone home - git and syncthing, no ssh-agent
  test-landed-hm-laptop = {
    expr =
      let
        l = r.landed.homeManager.${i.user i.laptop "alice"};
      in
      [
        (has l "dev")
        (has l "sync")
        (has l "ssh-agent")
      ];
    expected = [
      true
      true
      false
    ];
  };
  # row: darwin + os: dock on studio; no nixos content on studio
  test-landed-darwin-dock = {
    expr = has r.landed.darwin.${i.studio} "dock";
    expected = true;
  };
  test-landed-nixos-not-studio = {
    expr = r.landed.nixos ? ${i.studio};
    expected = false;
  };
  # kernel `at = ren.kinds.host` matches ci (guest `is = host`, fleet.md:91);
  # impermanence `at = metal` = host and not guest (fleet.md:126) does not
  test-landed-nixos-kernel-not-impermanence-on-ci = {
    expr = [
      (has r.landed.nixos.${i.ci} "kernel")
      (has r.landed.nixos.${i.ci} "impermanence")
    ];
    expected = [
      true
      false
    ];
  };

  # ── branches ──
  test-branches-nixos = {
    expr = [
      r.branches.nixos.${i.lb}
      r.branches.nixos.${i.ci}
    ];
    expected = [
      0
      1
    ];
  };
  test-branches-os = {
    expr = [
      r.branches.os.${i.lb}
      r.branches.os.${i.studio}
    ];
    expected = [
      0
      1
    ];
  };
  test-branches-homemanager-four-homes = {
    expr = map (id: r.branches.homeManager.${id}) [
      (i.user i.lb "alice")
      (i.user i.studio "alice")
      (i.user i.pixel "alice")
      (i.user i.laptop "alice")
    ];
    expected = [
      0
      1
      2
      3
    ];
  };
  # a user under a guest is within a host: branch 0 (forwards to ci's nixos)
  test-branches-homemanager-ci-user = {
    expr = r.branches.homeManager.${i.user i.ci "bob"};
    expected = 0;
  };

  # ── forwarded ──
  # row: chained forward (bob's HM in ci -> ci's nixos -> stage's microvm.vms.ci)
  test-forwarded-stage-has-ci = {
    expr = has r.forwarded.nixos.${i.stage} i.ci;
    expected = true;
  };
  test-forwarded-ci-has-its-users = {
    expr = map (u: has r.forwarded.nixos.${i.ci} (i.user i.ci u)) [
      "alice"
      "bob"
    ];
    expected = [
      true
      true
    ];
  };
  test-forwarded-stage-not-ci-users = {
    expr = map (u: has r.forwarded.nixos.${i.stage} (i.user i.ci u)) [
      "alice"
      "bob"
    ];
    expected = [
      false
      false
    ];
  };
  test-forwarded-stage-has-own-users = {
    expr = map (u: has r.forwarded.nixos.${i.stage} (i.user i.stage u)) [
      "alice"
      "bob"
    ];
    expected = [
      true
      true
    ];
  };
  # row: darwin + os
  test-forwarded-darwin-studio-users = {
    expr = map (u: has r.forwarded.darwin.${i.studio} (i.user i.studio u)) [
      "alice"
      "bob"
    ];
    expected = [
      true
      true
    ];
  };
  test-forwarded-nixos-never-studio = {
    expr = r.forwarded.nixos ? ${i.studio};
    expected = false;
  };
  # homeDarwin forwards in place into homeManager
  test-forwarded-homedarwin-into-hm = {
    expr = has r.forwarded.homeManager.${i.user i.studio "alice"} (i.user i.studio "alice");
    expected = true;
  };
  test-forwarded-droid-pixel = {
    expr = r.forwarded.droid.${i.pixel};
    expected = [ (i.user i.pixel "alice") ];
  };
  # UNTESTABLE-T1: guest channel (ci built with stable pkgs inside edge stage) - needs pkgs
  # UNTESTABLE-T1: microvm.vms.ci.config / bob's ci home absent from stage home-manager.users - forces nixos module values
  # UNTESTABLE-T1: kernel channel from settings (lts/latest) - forces pkgs
  # UNTESTABLE-T1: syncthing tray via `is desktop parent` - forces homeManager module values
  # UNTESTABLE-T1: per-branch stratum 3 reads outputs (C7: no Fleet branch reads outputs; lib tests use a synthetic vocabulary)
  # UNTESTABLE-T1: lb haproxy config text "web-1, web-2" - forces a realized nixosSystem (pool order covered in pools.nix)
  # UNTESTABLE-T1: flake-file.inputs as a real option beside nixosConfigurations - flake-file module not in Tier 1
}
