# Kernel: the nearest kernel.channel setting (host, environment, inherited environment) wins.
{
  ren,
  lib,
  ...
}:
let
  inherit (ren.lib) maybe;
  first = lib.findFirst (v: v != null) null; # nearest non-null wins
in
{
  ren.helpers.settingsT = lib.types.submodule {
    options.kernel.channel = maybe (
      lib.types.enum [
        "lts"
        "latest"
      ]
    );
  };

  ren.aspects.kernel = {
    at = ren.kinds.host;
    nixos =
      {
        host,
        environment,
        pkgs,
        ...
      }:
      let
        k = first [
          host.settings.kernel.channel
          environment.settings.kernel.channel
          (environment.inherits.settings.kernel.channel or null)
          "latest"
        ];
      in
      {
        boot.kernelPackages = if k == "lts" then pkgs.linuxPackages else pkgs.linuxPackages_latest;
      };
  };
}
