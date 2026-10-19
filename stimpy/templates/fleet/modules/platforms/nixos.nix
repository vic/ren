# NixOS: the host kind and the nixos class (metal hosts build; guests forward to their host).
{
  ren,
  lib,
  ...
}:
let
  inherit (ren.helpers) usersOn metal pkgsOf;
  inherit (ren.lib) same;
in
{
  # ══ CLASSES — module systems (gen-aspects `class`); into returns top-level options ══
  ren.classes.nixos = [
    {
      at = metal;
      into =
        { host, deployment, ... }:
        ms:
        let
          sys = host.channel.nixpkgs.lib.nixosSystem {
            system = host.system.name;
            modules = ms;
          };
        in
        {
          nixosConfigurations.${host.name} = sys;
          colmena.${host.name} = {
            imports = ms;
            deployment = {
              targetHost = deployment.address;
              inherit (deployment) tags;
            };
          }; # channel
          age-manifest.${host.name} = lib.attrNames sys.config.age.secrets; # channel
          deploy.nodes.${host.name} = {
            hostname = deployment.address;
            sshUser = deployment.user;
          };
        };
    }
    {
      at = ren.kinds.guest; # forwards to the physical host
      into = { guest, ... }: ms: {
        nixos.microvm.vms.${guest.name} = {
          pkgs = pkgsOf guest;
          config.imports = ms;
        };
      };
    }
  ];

  ren.kinds.host = {
    is = ren.kinds.machine;
    below = [
      ren.kinds.user
      ren.kinds.guest
    ];
    spawns = {
      user = usersOn;
      guest = s: lib.filterAttrs (_: g: same g.on s.host) ren.guest;
    };
  };
}
