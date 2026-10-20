# e2e rows of the fleet "Expected result" that need realized config.
let
  inputs = import ../e2e.nix;
  o = inputs.impl.lib.mkFlake inputs (inputs.import-tree ../modules);
  lib = inputs.nixpkgs.lib;
  pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
  nixos = n: o.nixosConfigurations.${n}.config;
  stage = nixos "stage";
  ci = stage.microvm.vms.ci.config.config;
  home = o.homeConfigurations.alice-laptop.config;
  persist = map (d: d.directory) stage.environment.persistence."/persist".directories; # submodule list
  release = hm: (lib.importJSON "${hm}/release.json").release;
  helix = p: p.helix.version;
in
import ./class-lib.nix { inherit inputs; }
// {
  # README.md#features: ci builds with stable pkgs inside edge stage
  test-guest-ci-stable-pkgs = {
    expr = toString stage.microvm.vms.ci.pkgs.path;
    expected = toString inputs.nixpkgs.outPath;
  };
  # README.md#features: the standalone home uses edge HM (stable HM has another release)
  test-home-edge-hm = {
    expr = home.home.version.release;
    expected = release inputs.home-manager-unstable;
  };
  # README.md#features: alice + bob HM under darwin
  test-darwin-hm-users = {
    expr = builtins.attrNames o.darwinConfigurations.studio.config.home-manager.users;
    expected = [
      "alice"
      "bob"
    ];
  };
  # README.md#features: aerospace on studio homes, not on linux homes
  test-aerospace-studio-not-lb = {
    expr = [
      o.darwinConfigurations.studio.config.home-manager.users.bob.programs.aerospace.enable
      (nixos "lb").home-manager.users.alice.programs.aerospace.enable
    ];
    expected = [
      true
      false
    ];
  };
  # README.md#features: every machine gets the edge helix (stable helix has another version)
  test-overlays-helix-every-machine = {
    expr = lib.unique (
      map (n: helix o.nixosConfigurations.${n}.pkgs) [
        "lb"
        "web-1"
        "web-2"
        "stage"
      ]
      ++ [
        (helix stage.microvm.vms.ci.config._module.args.pkgs)
        (helix o.darwinConfigurations.studio.pkgs)
      ]
    );
    expected = [ (helix inputs.nixpkgs-unstable.legacyPackages.x86_64-linux) ];
  };
  # README.md#expected-results: the nixos class feeds the colmena and age-manifest channels
  test-channel-into-colmena-age = {
    expr = [
      (builtins.attrNames o.colmenaHive.nodes)
      (builtins.attrNames o.ageManifest)
    ];
    expected = lib.genList (_: [
      "lb"
      "stage"
      "web-1"
      "web-2"
    ]) 2;
  };
  test-hostname = {
    expr = (nixos "lb").networking.hostName;
    expected = "lb";
  };
  test-substitute-web-2 = {
    expr = (nixos "web-2").environment.etc.motd.text;
    expected = "ren";
  };
  test-substitute-lb = {
    expr = (nixos "lb").environment.etc.motd.text;
    expected = "managed by ren";
  };
  test-fold-one = {
    expr = o.deploy.nodes.lb.hostname;
    expected = "10.0.1.1";
  };
  test-fold-list-order = {
    expr =
      let
        cfg = (nixos "lb").services.haproxy.config;
      in
      lib.hasInfix "10.0.1.10" (builtins.head (lib.splitString "10.0.1.11" cfg))
      && lib.hasInfix "10.0.1.11" cfg;
    expected = true;
  };
  test-guest-vm = {
    expr = ci.networking.hostName;
    expected = "ci";
  };
  test-chained-forward-stage-users = {
    expr = builtins.attrNames stage.home-manager.users;
    expected = [
      "alice"
      "bob"
    ];
  };
  test-chained-forward-ci-bob = {
    expr = ci.home-manager.users ? bob;
    expected = true;
  };
  test-kernel-lts = {
    expr = (nixos "lb").boot.kernelPackages.kernel.version;
    expected = pkgs.linuxPackages.kernel.version;
  };
  test-kernel-latest = {
    expr = (nixos "web-1").boot.kernelPackages.kernel.version;
    expected = pkgs.linuxPackages_latest.kernel.version;
  };
  test-persist-members = {
    expr = lib.all (d: builtins.elem d persist) [
      "/var/lib/nginx"
      "/var/lib/docker"
    ];
    expected = true;
  };
  test-persist-no-dups = {
    expr = lib.unique persist == persist;
    expected = true;
  };
  test-overlays = {
    expr = builtins.length (nixos "lb").nixpkgs.overlays;
    expected = 1;
  };
  test-packages-hello = {
    expr = o.packages.x86_64-linux.hello.type;
    expected = "derivation";
  };
  test-home-git = {
    expr = home.programs.git.enable;
    expected = true;
  };
  test-home-syncthing = {
    expr = home.services.syncthing.enable;
    expected = true;
  };
  # README.md#expected-results, README.md#features: `is ren.aspects.desktop parent` on the path: tray on for stage users only
  test-tray-stage-alice = {
    expr = stage.home-manager.users.alice.services.syncthing.tray.enable;
    expected = true;
  };
  test-tray-lb-alice = {
    expr = (nixos "lb").home-manager.users.alice.services.syncthing.tray.enable;
    expected = false;
  };
  test-home-no-ssh-agent = {
    expr = home.services.ssh-agent.enable;
    expected = false;
  };
  test-darwin-hostname = {
    expr = o.darwinConfigurations.studio.config.networking.hostName;
    expected = "studio";
  };
  test-darwin-dock = {
    expr = o.darwinConfigurations.studio.config.system.defaults.dock.autohide;
    expected = true;
  };
  # README.md#features: motd evaluates on darwin (README.md#features)
  test-darwin-motd = {
    expr = o.darwinConfigurations.studio.config.environment.etc.motd.text;
    expected = "managed by ren";
  };
  # README.md#features: dev lands git as a package on every os (README.md#features)
  test-darwin-git-pkg = {
    expr = lib.any (
      p: (p.pname or "") == "git"
    ) o.darwinConfigurations.studio.config.environment.systemPackages;
    expected = true;
  };
  test-nixos-lb-git-pkg = {
    expr = lib.any (p: (p.pname or "") == "git") (nixos "lb").environment.systemPackages;
    expected = true;
  };
  test-flake-file-inputs = {
    expr = lib.all (n: o.flake-file.inputs ? ${n}) [
      "agenix"
      "microvm"
    ];
    expected = true;
  };
}
// import ./demos.nix { inherit o lib; }
// import ./diamond.nix { inherit o lib; }
