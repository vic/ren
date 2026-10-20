# flakeModule (issue #33): the fleet is an option; `flake` = mkFlake. Host-agnostic:
# flake-parts, plain lib.evalModules, or Gen's evalModuleTree (Ren). Needs `inputs` as a module arg.
# The host declares `flake` (flake-parts does; plain hosts add `options.flake`).
stimpy: {
  flakeModule =
    {
      config,
      lib,
      inputs,
      ...
    }:
    {
      options.fleet = lib.mkOption {
        type = lib.types.deferredModule;
        default = { };
        description = "The fleet module (README.md#entry-points `mkFlake`).";
      };
      config.flake = stimpy.mkFlake inputs config.fleet;
    };
}
