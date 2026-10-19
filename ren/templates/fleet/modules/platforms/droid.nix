# nix-on-droid: the phone kind and the droid class.
{
  ren,
  lib,
  inputs,
  ...
}:
{
  ren.classes.droid = {
    at = ren.kinds.phone;
    into = { phone, ... }: ms: {
      nixOnDroidConfigurations.${phone.name} = inputs.nix-on-droid.lib.nixOnDroidConfiguration {
        pkgs = ren.helpers.pkgsOf phone;
        modules = ms;
      };
    };
  };

  ren.kinds.phone = {
    below = [ ren.kinds.user ];
    spawns.user = _: lib.filterAttrs (_: u: u.phone) ren.user;
    environment = ren.kinds.environment;
    channel = ren.kinds.channel;
    system = ren.kinds.system;
  };
}
