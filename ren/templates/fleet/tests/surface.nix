{ ev, ... }:
let
  i = import ./_ids.nix;
  # a root emission whose value is f ren, read back from the flake-inputs pool
  probe =
    f:
    (ev (
      { ren, ... }:
      {
        ren.aspects.probe = {
          at = ren.fleet.main;
          flake-inputs = { ... }: { probe = f ren; };
        };
      }
    )).pools.flake-inputs.${i.root}.probe;
in
{
  # control: the probe reads module values back
  test-probe-control = {
    expr = probe (ren: ren.host.stage.name);
    expected = "stage";
  };
  # README.md#aspects, README.md#vocabulary: `is P x` is an eval error when x has no scope on the current path (a bare instance)
  test-is-bare-instance-throws = {
    expr = probe (ren: ren.lib.is ren.aspects.desktop ren.host.stage);
    expectedError.type = "ThrownError";
  };
  # README.md#expected-results, README.md#vocabulary: Ren exports `anyOf`, never `any` (gen-select's tombstone)
  test-anyOf-not-any = {
    expr = probe (ren: {
      anyOf = ren.lib ? anyOf;
      any = ren.lib ? any;
    });
    expected = {
      anyOf = true;
      any = false;
    };
  };
}
