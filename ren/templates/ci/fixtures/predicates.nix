# Shared fixtures for the predicates tests (not a test module).
# Real kinds, instances and scopes, read through the pipeline's ctx (predicates.mkCtx).
{ ren, lib }:
rec {
  p = ren.predicates;
  K = ren.kinds.mkKinds {
    inherit lib;
    decls = {
      root.below = [ K.env ];
      env.below = [
        K.host
        K.guest
      ];
      machine = { };
      host = {
        is = K.machine;
        below = [ K.user ];
        # host h holds user u; host h2 holds a user named like host h (user:h vs machine:h)
        spawns.user = s: if s.name == "h" then { inherit (I.user) u; } else { inherit (I.user) h; };
      };
      guest.is = K.host;
      user = { };
      other = { };
    };
  };
  I = ren.kinds.mkInstances {
    inherit lib;
    kinds = K;
    decls = {
      root.r = { };
      env.e = { };
      host = {
        h = { };
        h2 = { };
      };
      guest.g = { };
      user = {
        u = { };
        h = { };
      };
      other.zzz = { };
    };
  };
  sc = ren.scopes.mkScopes {
    kinds = K;
    instances = I;
  };
  ctx = p.mkCtx {
    kinds = K;
    inherit sc;
  };
  env = "root:r/env:e";
  ids = {
    root = "root:r";
    inherit env;
    host = "${env}/host:h";
    host2 = "${env}/host:h2";
    guest = "${env}/guest:g";
    user = "${env}/host:h/user:u";
    userh = "${env}/host:h2/user:h";
  };
  insts = {
    inherit (I.host) h h2;
    inherit (I.user) u;
    uh = I.user.h;
    inherit (I.guest) g;
    inherit (I.other) zzz;
  };
  inst = n: insts.${n};
  kind = n: K.${n};
  t = q: n: p.test ctx { } q ids.${n};
  hostK = K.host;
}
