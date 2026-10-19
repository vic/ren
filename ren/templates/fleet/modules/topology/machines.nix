# Machines: the abstract kind every host, guest and mac is, and what each one gets.
{
  ren,
  lib,
  settingsT,
  opt,
  ...
}:
let
  inherit (ren.lib) and not;
in
{
  _module.args.metal = and [
    ren.kinds.host
    (not ren.kinds.guest)
  ]; # physical nixos hosts

  ren.kinds.machine = {
    # abstract: no `below` lists it
    environment = ren.kinds.environment;
    channel = ren.kinds.channel;
    system = ren.kinds.system;
    addr = lib.types.str;
    settings = opt settingsT { };
  };

  ren.aspects.base = {
    at = ren.kinds.machine;
    os = { machine, overlays, ... }: {
      networking.hostName = machine.name;
      nixpkgs.overlays = overlays;
    };
  };
}
