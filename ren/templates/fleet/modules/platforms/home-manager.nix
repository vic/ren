# home-manager: the homeManager class (four homes), the standalone home kind, and the home defaults.
{
  ren,
  ...
}:
let
  inherit (ren.helpers) pkgsOf;
  inherit (ren.lib) and within;
in
{
  ren.classes.homeManager = [
    # one class, four homes
    {
      at = and [
        ren.kinds.user
        (within ren.kinds.host)
      ];
      into = { user, ... }: ms: { nixos.home-manager.users.${user.name}.imports = ms; };
    }
    {
      at = and [
        ren.kinds.user
        (within ren.kinds.mac)
      ];
      into = { user, ... }: ms: { darwin.home-manager.users.${user.name}.imports = ms; };
    }
    {
      at = and [
        ren.kinds.user
        (within ren.kinds.phone)
      ];
      into = { ... }: ms: { droid.home-manager.config.imports = ms; };
    }
    {
      at = and [
        ren.kinds.user
        (within ren.kinds.home)
      ]; # standalone
      into = { home, ... }: ms: {
        homeConfigurations.${home.name} = home.channel.home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsOf home;
          modules = ms;
        };
      };
    }
  ];

  ren.kinds.home = {
    below = [ ren.kinds.user ];
    spawns.user = s: { ${s.home.user.name} = s.home.user; }; # standalone
    user = ren.kinds.user;
    channel = ren.kinds.channel;
    system = ren.kinds.system;
  };

  ren.aspects.hm-module = {
    # bundle: each key lands where its class lives
    at = ren.kinds.machine;
    nixos = { host, ... }: { imports = [ host.channel.home-manager.nixosModules.home-manager ]; };
    darwin = { mac, ... }: { imports = [ mac.channel.home-manager.darwinModules.home-manager ]; };
  };
  ren.aspects.hm-state = {
    at = ren.kinds.user;
    homeManager.home.stateVersion = "25.05";
  }; # README.md#platforms
  ren.aspects.hm-standalone = {
    at = and [
      ren.kinds.user
      (within ren.kinds.home)
    ];
    homeManager =
      { user, ... }:
      {
        home.username = user.name;
        home.homeDirectory = "/home/${user.name}";
      };
  }; # README.md#platforms
}
