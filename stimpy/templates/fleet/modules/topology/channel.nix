# Package channels: which nixpkgs, home-manager and nix-darwin a scope builds with.
{
  ren,
  lib,
  inputs,
  ...
}:
let
  inherit (ren.lib) opt;
  t = lib.types;
in
{
  ren.helpers.pkgsOf = m: m.channel.nixpkgs.legacyPackages.${m.system.name}; # m: anything with channel + system

  ren.kinds.channel = {
    nixpkgs = t.raw;
    home-manager = t.raw;
    darwin = opt t.raw null;
  };

  ren.channel.stable = {
    nixpkgs = inputs.nixpkgs;
    home-manager = inputs.home-manager;
    darwin = inputs.nix-darwin;
  };
  ren.channel.edge = {
    nixpkgs = inputs.nixpkgs-unstable;
    home-manager = inputs.home-manager-unstable;
  };
}
