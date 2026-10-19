# Machines: the abstract kind every host, guest and mac is, and what each one gets.
{
  ren,
  lib,
  ...
}:
let
  inherit (ren.helpers) settingsT opt maybe;
  inherit (ren.lib) and not;
in
{
  ren.helpers.metal = and [
    ren.kinds.host
    (not ren.kinds.guest)
  ]; # physical nixos hosts

  ren.kinds.machine = {
    # abstract: no `below` lists it
    environment = ren.kinds.environment;
    channel = ren.kinds.channel;
    system = ren.kinds.system;
    addr = lib.types.str;
    buildHost = maybe lib.types.str; # null: build on the deployer
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
