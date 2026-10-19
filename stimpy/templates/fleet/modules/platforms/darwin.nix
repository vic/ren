# nix-darwin: the mac kind, the darwin class and the homeDarwin sub-class.
{
  ren,
  ...
}:
let
  inherit (ren.helpers) usersOn;
  inherit (ren.lib) and within;
in
{
  ren.classes.darwin = {
    at = ren.kinds.mac;
    into = { mac, ... }: ms: {
      darwinConfigurations.${mac.name} = mac.channel.darwin.lib.darwinSystem {
        system = mac.system.name;
        modules = ms;
      };
    };
  };

  ren.classes.homeDarwin = {
    # a sub-class, forwarded in place
    at = and [
      ren.kinds.user
      (within ren.kinds.mac)
    ];
    into = { ... }: ms: { homeManager.imports = ms; };
  };

  ren.kinds.mac = {
    is = ren.kinds.machine;
    below = [ ren.kinds.user ];
    spawns.user = usersOn;
  };

  ren.aspects.dock = {
    at = ren.kinds.mac;
    darwin.system.defaults.dock.autohide = true;
  };
  ren.aspects.tiling = {
    at = ren.kinds.user; # lands only on mac users
    homeDarwin.programs.aerospace.enable = true;
  };
}
