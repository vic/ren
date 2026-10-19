{ ren, lib }:
let
  inherit (import ../../fixtures/kinds.nix { inherit ren lib; })
    kinds
    mk
    boom
    anInst
    replicas
    ;
in
{
  kinds = {
    test-missing-field = {
      expr = boom (mk {
        host.x = { };
      });
      expected = false;
    };
    test-missing-field-msg = {
      expr = (mk { host.x = { }; }).host.x.addr;
      expectedError.type = "ThrownError";
      expectedError.msg = "option `host.x.addr' is used but not defined";
    };
    test-unknown-field = {
      expr = boom (mk {
        host.x = {
          addr = "1";
          nope = 1;
        };
      });
      expected = false;
    };
    test-name-clash = {
      expr = boom (mk {
        host.ci.addr = "1";
        guest.ci = {
          addr = "2";
          on = anInst;
        };
      });
      expected = false;
    };
    test-name-clash-msg = {
      expr =
        (mk {
          host.ci.addr = "1";
          guest.ci = {
            addr = "2";
            on = anInst;
          };
        }).host.ci;
      expectedError.type = "ThrownError";
      expectedError.msg = "used by both kind";
    };
    test-fn-form-fields = {
      expr = builtins.attrNames kinds.replica.schema.options;
      expected = [
        "db"
        "region"
      ];
    };
    test-guard-violated = {
      expr = (replicas "us").replica.r;
      expectedError.type = "ThrownError";
      expectedError.msg = "kind `replica` violates its kind guard";
    };
    test-name-with-slash-refused = {
      expr =
        (ren.kinds.mkInstances {
          inherit lib kinds;
          decls.host."a/b".addr = "1";
        }).host."a/b";
      expectedError.type = "ThrownError";
      expectedError.msg = "instance name `a/b` .* must not contain";
    };
    test-guard-satisfied = {
      expr = (replicas "eu").replica.r.name;
      expected = "r";
    };
    test-spawns-not-in-below-no-instances = {
      expr =
        (ren.kinds.mkKinds {
          inherit lib;
          decls.a = {
            below = [ ];
            spawns.b = _: { };
          };
        }).a;
      expectedError.type = "ThrownError";
      expectedError.msg = "kind `a` spawns `b` not in below";
    };
  };
}
