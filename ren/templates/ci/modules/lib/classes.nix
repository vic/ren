{ ren, lib }:
let
  inherit (import ../../fixtures/classes.nix { inherit ren lib; })
    c
    mk
    refused
    r
    ;
in
{
  classes = {
    test-chained-forward = {
      expr = r.outputs.outputs.nixosConfigurations.stage;
      expected = [
        "nixos:stage"
        {
          vms.ci = [
            "nixos:ci"
            { users.bob = [ "hm:bob" ]; }
          ];
        }
      ];
    };
    test-output-merge-disjoint = {
      expr =
        (c.mergeOutputs [
          { a.x = 1; }
          { a.y = 2; }
        ]).a;
      expected = {
        x = 1;
        y = 2;
      };
    };
    test-output-conflict = {
      expr = refused (
        c.mergeOutputs [
          { a.x = 1; }
          { a.x = 2; }
        ]
      );
      expected = false;
    };
    # a class named like its own output key writes an output, not a forward to itself
    test-own-name-key-is-output = {
      expr =
        (mk {
          cls.checks = {
            id = "stage";
            into = _: _: { checks.x = 1; };
          };
          order = [ "stage" ];
        }).outputs.checks;
      expected.x = 1;
    };
    # negative control: another class's name still forwards, and without a branch it is refused
    test-other-key-still-forward = {
      expr =
        refused
          (mk {
            cls = {
              checks = {
                id = "stage";
                into = _: _: { nixos.x = 1; };
              };
              nixos = {
                id = "nowhere";
                into = _: _: { };
              };
            };
            order = [ "stage" ];
          }).outputs;
      expected = false;
    };
    test-no-target = {
      expr =
        refused
          (mk {
            order = [ "bob" ];
            anc = _: [ ];
          }).outputs;
      expected = false;
    };
    test-two-branches = {
      expr =
        refused
          (mk {
            cls.nixos = [
              {
                id = "stage";
                into = _: _: { };
              }
              {
                id = "stage";
                into = _: _: { };
              }
            ];
          }).outputs;
      expected = false;
    };
  };
}
