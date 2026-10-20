{
  lib,
  r,
  ev,
  ...
}:
let
  i = import ./_ids.nix;
  ids = builtins.attrNames r.scopes;
  # names of the user scopes directly under parent id
  usersOf =
    p:
    map (lib.removePrefix "${p}/user:") (
      lib.filter (
        id: lib.hasPrefix "${p}/user:" id && !lib.hasInfix "/" (lib.removePrefix "${p}/user:" id)
      ) ids
    );
  ciExtra =
    { ren, ... }:
    {
      ren.guest.x = {
        environment = ren.environment.staging;
        channel = ren.channel.stable;
        system = ren.system.x86_64-linux;
        addr = "10.9.9.9";
        on = ren.guest.ci;
      };
    };
in
{
  # row: root kinds (README.md#kinds) + tree shape; 26 = 8 (root, 3 system, 2 env, home, replica) + 7 machines/phone + 11 users
  test-scopes-total = {
    expr = lib.length ids;
    expected = 26;
  };
  test-scopes-top = {
    expr = lib.filter (id: builtins.length (lib.splitString "/" id) <= 2) ids;
    expected = lib.sort lib.lessThan [
      i.root
      (i.sys "x86_64-linux")
      (i.sys "aarch64-linux")
      (i.sys "aarch64-darwin")
      i.prod
      i.staging
      i.laptop
      i.replica
    ];
  };
  test-scopes-replica-exists = {
    expr = r.scopes ? ${i.replica};
    expected = true;
  };
  # row: parent-side spawns
  test-spawn-lb-only-alice = {
    expr = usersOf i.lb;
    expected = [ "alice" ];
  };
  test-spawn-web-only-alice = {
    expr = [
      (usersOf i.web1)
      (usersOf i.web2)
    ];
    expected = [
      [ "alice" ]
      [ "alice" ]
    ];
  };
  test-spawn-stage = {
    expr = lib.sort lib.lessThan (usersOf i.stage);
    expected = [
      "alice"
      "bob"
    ];
  };
  test-spawn-ci = {
    expr = lib.sort lib.lessThan (usersOf i.ci);
    expected = [
      "alice"
      "bob"
    ];
  };
  test-spawn-studio = {
    expr = lib.sort lib.lessThan (usersOf i.studio);
    expected = [
      "alice"
      "bob"
    ];
  };
  test-spawn-pixel-only-alice = {
    expr = usersOf i.pixel;
    expected = [ "alice" ];
  };
  test-spawn-alice-laptop = {
    expr = usersOf i.laptop;
    expected = [ "alice" ];
  };
  test-spawn-user-count = {
    expr = lib.length (lib.filter (id: lib.hasInfix "/user:" id) ids);
    expected = 11;
  };
  # row: no guest in a guest
  test-no-guest-in-guest = {
    expr = lib.filter (id: builtins.match ".*guest:.*guest:.*" id != null) ids;
    expected = [ ];
  };
  test-extra-guest-on-guest-no-scope = {
    expr = lib.filter (id: lib.hasInfix "guest:x" id) (builtins.attrNames (ev ciExtra).scopes);
    expected = [ ];
  };
  # row: identity without scopes (groups, channels, db, region never spawn; machine is abstract)
  test-data-kinds-have-no-scopes = {
    expr = lib.filter (
      id:
      lib.any (k: lib.hasInfix "/${k}:" id || lib.hasPrefix "${k}:" id) [
        "group"
        "channel"
        "db"
        "region"
        "machine"
      ]
    ) ids;
    expected = [ ];
  };
  # row: guest channel (scope identity half): ci is a distinct scope under stage
  test-ci-under-stage = {
    expr = r.scopes ? ${i.ci};
    expected = true;
  };
  # UNTESTABLE-T1: guest channel (ci built with stable pkgs) - needs a realized nixpkgs / pkgs
  # UNTESTABLE-T1: identity without scopes (closure/granted via same) - covered indirectly by spawn-* tests
}
