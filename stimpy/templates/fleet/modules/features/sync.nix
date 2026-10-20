# Sync: syncthing for every user; each user's devices are the machines it lives on.
{ ren, ... }:
let
  inherit (ren.lib)
    and
    not
    when
    is
    same
    ;
in
{
  ren.channels.devices = {
    fold = ren.lib.fold.set;
    at = ren.kinds.user;
    to =
      e:
      and [
        ren.kinds.user
        (when (r: same r.user e.user))
        (not e)
      ];
  };

  ren.aspects.sync = {
    at = ren.kinds.user;
    devices = { parent, ... }: parent.name;
    persist = { user, ... }: "/home/${user.name}/.local/state/syncthing";
    homeManager =
      {
        devices,
        parent,
        lib,
        ...
      }:
      {
        services.syncthing.enable = true;
        services.syncthing.settings.devices = lib.genAttrs devices (n: {
          id = builtins.hashString "sha256" n;
        }); # README.md#features
        services.syncthing.tray.enable = is ren.aspects.desktop parent; # same `is` as everywhere
      };
  };
}
