# Environments: the machines in each one, and the groups it grants.
{
  ren,
  lib,
  ...
}:
let
  inherit (ren.helpers) opt maybe settingsT;
  t = lib.types;
  inherit (ren.lib) same;
  inEnv = xs: s: lib.filterAttrs (_: x: same x.environment s.environment) xs;
in
{
  ren.kinds.environment = {
    below = [
      ren.kinds.host
      ren.kinds.mac
      ren.kinds.phone
    ];
    spawns = {
      host = inEnv ren.host;
      mac = inEnv ren.mac;
      phone = inEnv ren.phone;
    };
    grants = t.listOf ren.kinds.group;
    edge = opt t.bool false;
    inherits = maybe ren.kinds.environment;
    settings = opt settingsT { };
  };

  ren.environment.prod = {
    grants = [ ren.group.admin ];
    edge = true;
    settings.kernel.channel = "lts";
  };
  ren.environment.staging = {
    grants = [
      ren.group.admin
      ren.group.deploy
    ];
    inherits = ren.environment.prod;
  };
}
