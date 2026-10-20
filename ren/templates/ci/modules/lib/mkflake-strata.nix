{ ren, lib }:
let
  # mini fleet (README.md#evaluation-order row 3): `home` within a box forwards into `sys` and reads
  # `outputs.systems` (sys's output: a cycle); `home` within a pad forwards nothing and may read it
  mini =
    { ren, ... }:
    let
      inherit (ren.lib) and within;
    in
    {
      ren.classes = {
        sys = {
          at = ren.kinds.box;
          into = { box, ... }: ms: { systems.${box.name} = ms; };
        };
        home = [
          {
            at = and [
              ren.kinds.person
              (within ren.kinds.box)
            ];
            into = { person, outputs, ... }: _: {
              sys.users.${person.name} = builtins.attrNames outputs.systems;
            };
          }
          {
            at = and [
              ren.kinds.person
              (within ren.kinds.pad)
            ];
            into = { person, outputs, ... }: _: { homes.${person.name} = builtins.attrNames outputs.systems; };
          }
        ];
      };
      ren.kinds = {
        root.below = [
          ren.kinds.box
          ren.kinds.pad
        ];
        box.below = [ ren.kinds.person ];
        pad.below = [ ren.kinds.person ];
        person = { };
      };
      ren.root.r = { };
      ren.box.b = { };
      ren.pad.d = { };
      ren.person.p = { };
    };
  out = ren.mkFlake { nixpkgs = { inherit lib; }; } mini;
in
{
  mkflake-strata = {
    test-stratum3-forwarding-branch-reads-target = {
      expr = builtins.deepSeq out.systems out.systems;
      expectedError.type = "ThrownError";
      expectedError.msg = "stratum 3";
    };
    test-stratum3-standalone-branch-reads-outputs = {
      expr = out.homes;
      expected.p = [ "b" ];
    };
  };
}
