# Impermanence: hosts and their users emit state directories; each metal host persists them.
{
  ren,
  inputs,
  ...
}:
let
  inherit (ren.helpers) metal;
  inherit (ren.lib) and anyOf within;
in
{
  ren.channels.persist = {
    fold = ren.lib.fold.set;
    at = anyOf [
      ren.kinds.host
      (and [
        ren.kinds.user
        (within ren.kinds.host)
      ])
    ];
    to = e: e.host;
  }; # C1

  ren.aspects.impermanence = {
    at = metal;
    nixos = { persist, ... }: {
      imports = [ inputs.impermanence.nixosModules.impermanence ];
      environment.persistence."/persist".directories = persist;
    };
  };
}
