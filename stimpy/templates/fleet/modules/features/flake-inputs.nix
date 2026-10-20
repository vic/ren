# Flake inputs: any scope declares the inputs it needs; the channel forwards them to the flake-file class.
{ ren, lib, ... }:
{
  ren.channels.flake-inputs = {
    fold = ren.lib.fold.attrs;
    to = _: ren.fleet.main; # no `at`: any scope emits
    into = { ... }: inputs': { flake-file.inputs = inputs'; }; # a class key: forwarded as content
  };

  # class flake-file at the root writes its own name: the top-level `flake-file` output
  ren.classes.flake-file = {
    at = ren.kinds.fleet;
    into =
      { ... }:
      ms: {
        flake-file =
          (lib.evalModules {
            modules = ms ++ [ { freeformType = lib.types.attrsOf (lib.types.attrsOf lib.types.raw); } ];
          }).config;
      };
  };
}
