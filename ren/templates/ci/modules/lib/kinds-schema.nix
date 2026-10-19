# kinds as gen-schema kinds, instances from gen-schema registries (kinds.nix, kinds-check.nix).
{ ren, lib }:
let
  inherit (import ../../fixtures/kinds.nix { inherit ren lib; })
    kinds
    mk
    anInst
    ;
in
{
  kinds = {
    # `is` = gen-schema `inherits`: guest's ancestors are host and machine
    test-is-is-inherits = {
      expr = lib.sort (a: b: a < b) (
        map (k: k.kind) (builtins.attrValues kinds.guest.schema.__kindAncestors)
      );
      expected = [
        "host"
        "machine"
      ];
    };
    test-unknown-field-msg = {
      expr =
        (mk {
          host.x = {
            addr = "1";
            nope = 1;
          };
        }).host.x;
      expectedError.type = "ThrownError";
      expectedError.msg = "\"nope\" is not declared on host";
    };
    # identity keys = name only: id_hash never forces a field value
    test-id-hash-lazy-fields = {
      expr = builtins.isString (mk { host.x.addr = throw "forced"; }).host.x.id_hash;
      expected = true;
    };
    # control: the field itself does throw
    test-id-hash-lazy-fields-control = {
      expr = (mk { host.x.addr = throw "forced"; }).host.x.addr;
      expectedError.type = "ThrownError";
      expectedError.msg = "forced";
    };
  };
}
