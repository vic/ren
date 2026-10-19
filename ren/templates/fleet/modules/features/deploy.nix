# Deploy: each metal host emits one deployment record; colmena and deploy-rs read it.
{
  ren,
  inputs,
  metal,
  ...
}:
let
  inherit (ren.lib.fold) set attrs one;
in
{
  ren.channels.deployment = {
    fold = one;
    at = metal;
    to = e: e;
  };
  ren.channels.tags = {
    fold = set;
    to = e: e;
  };
  # channels with `into`: data collectors (not module systems, so not classes)
  ren.channels.colmena = {
    fold = attrs;
    at = metal;
    to = _: ren.fleet.main; # fed by the nixos collector
    into = { ... }: nodes: {
      colmenaHive = inputs.colmena.lib.makeHive (
        { meta.nixpkgs = inputs.nixpkgs.legacyPackages.x86_64-linux; } // nodes
      );
    };
  };

  ren.aspects.deploy-record = {
    at = metal;
    deployment = { host, tags, ... }: {
      address = host.addr;
      user = "deploy";
      inherit (host) buildHost;
      inherit tags;
    };
    generators = { host, ... }: {
      per-machine.${host.name}.deploy-key.files = [
        "key"
        "key.pub"
      ];
    };
  };
}
