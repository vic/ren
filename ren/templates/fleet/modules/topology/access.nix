# Access: users join groups; an environment grants groups; a machine spawns the granted users.
{
  ren,
  lib,
  ...
}:
let
  inherit (ren.helpers) opt;
  t = lib.types;
  inherit (ren.lib) same;
  closure =
    gs:
    map (x: x.g) (
      lib.genericClosure {
        # nested groups
        startSet = map (g: {
          key = g.name;
          inherit g;
        }) gs;
        operator =
          x:
          map (p: {
            key = p.name;
            g = p;
          }) (lib.filter (p: lib.any (same x.g) p.members) (lib.attrValues ren.group));
      }
    );
  granted = s: u: lib.any (g: lib.any (same g) s.environment.grants) (closure u.groups);
in
{
  ren.helpers.usersOn = s: lib.filterAttrs (_: granted s) ren.user;

  ren.kinds.group = {
    members = opt (t.listOf ren.kinds.group) [ ];
  };
  ren.kinds.user = {
    # each parent says how it spawns users
    groups = t.listOf ren.kinds.group;
    phone = opt t.bool false;
  };

  ren.group.ops = { };
  ren.group.admin = {
    members = [ ren.group.ops ];
  };
  ren.group.deploy = { };
}
