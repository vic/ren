{ lib, r, ... }:
let
  i = import ./_ids.nix;
  sorted = lib.sort lib.lessThan;
  aliceLb = i.user i.lb "alice";
in
{
  # row: fold = one
  test-deployment-lb-address = {
    expr = r.pools.deployment.${i.lb}.address;
    expected = "10.0.1.1";
  };
  test-deployment-lb-user = {
    expr = r.pools.deployment.${i.lb}.user;
    expected = "deploy";
  };
  # tags = the tags pool at the same scope; lb has no nginx so nothing was emitted there
  test-deployment-lb-tags-eq-pool = {
    expr = r.pools.deployment.${i.lb}.tags;
    expected = [ ];
  };
  # row: tags = emission (nginx emits "web" via tags; no reserved key)
  test-tags-stage-web = {
    expr = lib.elem "web" r.pools.tags.${i.stage};
    expected = true;
  };
  test-deployment-stage-tags-web = {
    expr = r.pools.deployment.${i.stage}.tags;
    expected = [ "web" ];
  };
  test-deployment-receivers-metal-only = {
    expr = sorted (builtins.attrNames r.pools.deployment);
    expected = sorted i.metals;
  };
  # row: fold = list order (scope-path order, not include order)
  test-backends-lb-exact = {
    expr = r.pools.backends.${i.lb};
    expected = [
      "10.0.1.10"
      "10.0.1.11"
    ];
  };
  # backends.to excludes nginx scopes (not ren.aspects.nginx) and other environments
  test-backends-no-nginx-receivers = {
    expr = lib.filter (
      id:
      lib.elem id [
        i.web1
        i.web2
        i.stage
      ]
    ) (builtins.attrNames r.pools.backends);
    expected = [ ];
  };
  # row: parent - alice@lb devices = the other 7 parents, scope-path (traversal) order:
  # README.md#features lists "stage, ci" (stage's own users precede the guest:ci subtree)
  test-devices-alice-lb = {
    expr = r.pools.devices.${aliceLb};
    expected = [
      "web-1"
      "web-2"
      "stage"
      "ci"
      "studio"
      "pixel"
      "alice-laptop"
    ];
  };
  test-devices-alice-lb-set = {
    expr = sorted r.pools.devices.${aliceLb};
    expected = sorted [
      "web-1"
      "web-2"
      "stage"
      "ci"
      "studio"
      "pixel"
      "alice-laptop"
    ];
  };
  test-devices-excludes-own-parent = {
    expr = lib.elem "lb" r.pools.devices.${aliceLb};
    expected = false;
  };
  test-devices-bob-stage = {
    expr = sorted r.pools.devices.${i.user i.stage "bob"};
    expected = sorted [
      "ci"
      "studio"
    ];
  };
  # row: impermanence (set): once each, ci's docker dir not on stage (README.md#features: to = e: e.host)
  test-persist-stage = {
    expr = sorted r.pools.persist.${i.stage};
    expected = sorted [
      "/var/lib/nginx"
      "/var/lib/docker"
      "/home/alice/.local/state/syncthing"
      "/home/bob/.local/state/syncthing"
    ];
  };
  test-persist-stage-count = {
    expr = lib.length r.pools.persist.${i.stage};
    expected = 4;
  };
  test-persist-ci-has-own-docker = {
    expr = lib.elem "/var/lib/docker" r.pools.persist.${i.ci};
    expected = true;
  };
  test-persist-lb-no-docker = {
    expr = lib.elem "/var/lib/docker" r.pools.persist.${i.lb};
    expected = false;
  };
  # users under mac/phone/home have no `host` binding: they emit nothing to persist (README.md#features)
  test-persist-receivers-hosts-only = {
    expr = lib.filter (
      id: lib.hasInfix "mac:" id || lib.hasInfix "phone:" id || lib.hasInfix "home:" id
    ) (builtins.attrNames r.pools.persist);
    expected = [ ];
  };
  # row: overlays - one overlay per machine, ci once (not again through stage)
  test-overlays-receivers = {
    expr = sorted (builtins.attrNames r.pools.overlays);
    expected = sorted i.machines;
  };
  test-overlays-one-each = {
    expr = map (m: builtins.length r.pools.overlays.${m}) i.machines;
    expected = [
      1
      1
      1
      1
      1
      1
    ];
  };
  test-overlays-ci-once = {
    expr = builtins.length r.pools.overlays.${i.ci};
    expected = 1;
  };
  # row: attrs recursive - records (to = prod env scope) merge from machine scopes
  test-records-prod = {
    expr = r.pools.records.${i.prod};
    expected = {
      lb = "10.0.1.1";
      web-1 = "10.0.1.10";
      web-2 = "10.0.1.11";
      stage = "10.0.2.10";
      ci = "10.0.2.20";
      studio = "10.0.2.30";
    };
  };
  # row: parent-side channels - replica scrape lands on lb
  test-scrape-lb = {
    expr = r.pools.scrape.${i.lb};
    expected = [
      {
        job = "r1";
        target = "eu.eu:9090";
      }
    ];
  };
  # row: flake-file / anywhere - agenix from secrets (lb, web-*, stage, ci emit the same url), microvm from vm
  test-flake-inputs-root = {
    expr = r.pools.flake-inputs.${i.root};
    expected = {
      agenix.url = "github:ryantm/agenix";
      microvm.url = "github:microvm-nix/microvm.nix";
    };
  };
  # row: channel into (README.md#channels) - one pool per system scope
  test-packages-pool-receivers = {
    expr = sorted (builtins.attrNames r.pools.packages);
    expected = sorted (
      map i.sys [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ]
    );
  };
  # UNTESTABLE-T1: per-system packages.<sys>.hello value (derivation: forces nixpkgs legacyPackages)
  # attrs-in-into conflict: conflicts.nix (probe channel; real hello derivations need pkgs)
  # UNTESTABLE-T1: colmenaHive / ageManifest fed by nixos collector (forces colmena input / realized system)
}
