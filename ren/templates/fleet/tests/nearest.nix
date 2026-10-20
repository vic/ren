# README.md#predicates `nearest K s`, `upTo K e`: a probe channel's receivers, from emitters `at`.
{ ev, ... }:
let
  i = import ./_ids.nix;
  bobCi = i.user i.ci "bob";
  bobStage = i.user i.stage "bob";
  recv =
    at: to:
    (ev (
      { ren, ... }:
      {
        ren.channels.probe-near = {
          fold = ren.lib.fold.list;
          at = at ren;
          to = to ren;
        };
        ren.aspects.probe-near = {
          at = at ren;
          probe-near = { ... }: 1;
        };
      }
    )).channels.probe-near.receivers;
  # emitters: users on a machine, and the machines
  onMachine =
    ren:
    ren.lib.anyOf [
      ren.kinds.machine
      (ren.lib.and [
        ren.kinds.user
        (ren.lib.within ren.kinds.machine)
      ])
    ];
  near = K: recv onMachine (ren: e: ren.lib.nearest (K ren) e);
  up = recv onMachine (ren: ren.lib.upTo ren.kinds.machine);
in
{
  # row: `nearest` follows `is` (guest is host is machine); bob on ci gets ci, never its host stage
  test-nearest-machine-guest = {
    expr = map (e: (near (ren: ren.kinds.machine)).${e}) [
      bobCi
      bobStage
      i.ci
    ];
    expected = [
      [ i.ci ]
      [ i.stage ]
      [ i.ci ]
    ];
  };
  # row: `nearest` walks past the machine to an ancestor kind
  test-nearest-environment = {
    expr = (near (ren: ren.kinds.environment)).${bobCi};
    expected = [ i.staging ];
  };
  # row: no such ancestor is null (the root has no machine above it)
  test-nearest-null-at-root = {
    expr =
      (recv (ren: ren.kinds.fleet) (
        ren: e: if ren.lib.nearest ren.kinds.machine e == null then e else ren.kinds.machine
      )).${i.root};
    expected = [ i.root ];
  };
  # row: `upTo` is the scope itself if a machine, plus the machine it is a child of (ci: stage too)
  test-upTo-machine = {
    expr = map (e: up.${e}) [
      bobCi
      bobStage
      i.stage
      i.ci
    ];
    expected = [
      [ i.ci ]
      [ i.stage ]
      [ i.stage ]
      [
        i.stage
        i.ci
      ]
    ];
  };
}
