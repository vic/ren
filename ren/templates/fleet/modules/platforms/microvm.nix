# MicroVM guests: a guest runs on a host; the host gets the microvm host module.
{
  ren,
  inputs,
  ...
}:
let
  inherit (ren.helpers) usersOn metal;
  inherit (ren.lib) and has;
in
{
  ren.kinds.guest = {
    is = ren.kinds.host; # declares its own `below`: no guest in a guest
    below = [ ren.kinds.user ];
    spawns.user = usersOn;
    on = ren.kinds.host;
  };

  ren.aspects.vm = {
    at = ren.kinds.guest;
    nixos.imports = [ inputs.microvm.nixosModules.microvm ];
    flake-inputs = { ... }: { microvm.url = "github:microvm-nix/microvm.nix"; };
  };
  ren.aspects.vm-host = {
    at = and [
      metal
      (has ren.kinds.guest)
    ];
    nixos.imports = [ inputs.microvm.nixosModules.host ];
  };
}
