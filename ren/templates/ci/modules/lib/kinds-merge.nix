{ ren, lib }:
let
  inherit (import ../../fixtures/mkflake.nix { inherit ren lib; }) inputs;
  # one kind declared in two files (vic/ren#19): fields, `below` and `spawns` merge
  two =
    second:
    ren.evalFleet inputs {
      imports = [
        (
          { ren, ... }:
          {
            ren.kinds = {
              root = {
                below = [ ren.kinds.box ];
                tag = lib.types.str;
              };
              box = { };
              pin = { };
            };
            ren.root.r.tag = "t";
            ren.box.b = { };
            ren.pin.p = { };
          }
        )
        second
      ];
    };
  more =
    { ren, ... }:
    {
      ren.kinds.root = {
        below = [ ren.kinds.pin ];
        spawns.pin = _: ren.pin;
        note = lib.types.str;
      };
      ren.root.r.note = "n";
    };
in
{
  kinds-merge = {
    test-kind-two-files-merge = {
      expr = builtins.attrNames (two more).scopes;
      expected = [
        "root:r"
        "root:r/box:b"
        "root:r/pin:p"
      ];
    };
    test-below-two-files-deduped = {
      expr =
        (lib.evalModules {
          modules = [
            { options.k = lib.mkOption { type = ren.declTypes.kind; }; }
            {
              k.below = [
                "a"
                "b"
              ];
            }
            {
              k.below = [
                "b"
                "a"
                "c"
              ];
            }
          ];
        }).config.k.below;
      expected = [
        "a"
        "b"
        "c"
      ];
    };
    test-kind-field-pkgs-refused = {
      expr = builtins.attrNames (two { ren.kinds.root.pkgs = lib.types.str; }).scopes;
      expectedError.type = "ThrownError";
      expectedError.msg = "field `pkgs` is reserved";
    };
    # negative control: the same field with a different type is a real clash
    test-kind-two-files-field-clash = {
      expr = builtins.attrNames (two { ren.kinds.root.tag = lib.types.int; }).scopes;
      expectedError.type = "ThrownError";
      expectedError.msg = "conflicting definitions";
    };
  };
}
