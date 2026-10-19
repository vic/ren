# Shared fixtures for the activation tests (not a test module).
{ ren, lib }:
rec {
  inst = kind: name: {
    __ren = "instance";
    __id = "${kind}:${name}";
    inherit kind name;
  };
  r = ren.scopes.mkScopes {
    kinds = {
      env.below = [ "host" ];
      host.below = [ "user" ];
      user = { };
    };
    instances = {
      env.prod = inst "env" "prod";
      host = {
        web-1 = inst "host" "web-1";
        web-2 = inst "host" "web-2";
        db = inst "host" "db";
      };
      user.alice = inst "user" "alice";
    };
  };
  ctx = {
    data = id: r.scopes.${id};
    parent = r.parentOf;
    inherit (r) children ancestors order;
    siblings = id: lib.remove id (r.children (r.parentOf id));
  };
  p = ren.predicates;
  kind = n: {
    __ren = "kind";
    name = n;
  };
  asp =
    name: extra:
    {
      __ren = "aspect";
      inherit name;
      at = null;
      includes = [ ];
      excludes = [ ];
    }
    // extra;
  h = n: "env:prod/host:${n}";
  u = n: "${h n}/user:alice";
  act = aspects: (ren.activation.mkActivation { inherit aspects ctx; }).active;

  motd = asp "motd" { at = kind "host"; };
  short = asp "motd-short" { };
  quiet = asp "quiet" {
    at = p.when (s: s.name == "web-2");
    excludes = [ motd ];
    includes = [ short ];
  };
  q = act {
    inherit motd quiet;
    "motd-short" = short;
  };
  nginx = asp "nginx" {
    at = p.and [
      (kind "host")
      (p.when (s: s.name != "db"))
    ];
  };
  httpPort = asp "http-port" {
    at = p.and [
      (kind "host")
      nginx
    ];
  };
  na = asp "a" { };
  nb = asp "b" { };
}
