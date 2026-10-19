# Shared fixtures for the activation tests (not a test module).
{ ren, lib }:
rec {
  K = ren.kinds.mkKinds {
    inherit lib;
    decls = {
      env.below = [ K.host ];
      host.below = [ K.user ];
      user = { };
    };
  };
  r = ren.scopes.mkScopes {
    kinds = K;
    instances = ren.kinds.mkInstances {
      inherit lib;
      kinds = K;
      decls = {
        env.prod = { };
        host = {
          web-1 = { };
          web-2 = { };
          db = { };
        };
        user.alice = { };
      };
    };
  };
  ctx = p.mkCtx {
    kinds = K;
    sc = r;
  };
  p = ren.predicates;
  kind = n: K.${n};
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
