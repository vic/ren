# Secrets: agenix on every host; the fleet collects one age manifest.
{
  ren,
  inputs,
  ...
}:
{
  ren.channels.age-manifest = {
    fold = ren.lib.fold.attrs;
    at = ren.helpers.metal;
    to = _: ren.fleet.main; # fed by the nixos collector
    into = { ... }: m: { ageManifest = m; };
  };

  ren.aspects.secrets = {
    at = ren.kinds.host;
    nixos.imports = [ inputs.agenix.nixosModules.default ];
    flake-inputs = { ... }: { agenix.url = "github:ryantm/agenix"; };
  };
}
