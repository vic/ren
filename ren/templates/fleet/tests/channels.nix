{ r, ... }:
let
  i = import ./_ids.nix;
  ci = r.scopes.${i.ci};
in
{
  # fleet.md:441: guest ci builds with its own `stable` channel while its host stage uses `edge`
  test-guest-ci-channel-stable = {
    expr = ci.guest.channel.name;
    expected = "stable";
  };
  test-guest-ci-parent-stage-edge = {
    expr = [
      ci.parent.name
      ci.parent.channel.name
    ];
    expected = [
      "stage"
      "edge"
    ];
  };
}
