{ ren, lib }:
let
  inherit (import ../../fixtures/predicates.nix { inherit ren lib; })
    p
    inst
    kind
    t
    hostK
    ;
in
{
  predicates = {
    test-kind = {
      expr = [
        (t hostK "host")
        (t hostK "user")
      ];
      expected = [
        true
        false
      ];
    };
    test-subkind = {
      expr = t (kind "machine") "host2";
      expected = true;
    };
    # gen-select subkind: guest `is = host` matches a host ref; a parent kind is not its child
    test-subkind-is-chain = {
      expr = [
        (t hostK "guest")
        (t (kind "machine") "guest")
        (t (kind "guest") "host")
        (t (kind "user") "guest")
      ];
      expected = [
        true
        true
        false
        false
      ];
    };
    # gen-select entity: user `h` and host `h` share a name, not an identity
    test-instance-other-family = {
      expr = [
        (t (inst "h") "userh")
        (t (inst "uh") "userh")
        (t (inst "uh") "host")
      ];
      expected = [
        false
        true
        false
      ];
    };
    # a kind ref is a gen-schema kind value; a bare name record is refused
    test-kind-ref-needs-schema = {
      expr = t {
        __ren = "kind";
        name = "host";
      } "host";
      expectedError.type = "EvalError";
    };
    test-instance = {
      expr = [
        (t (inst "h") "host")
        (t (inst "h") "host2")
      ];
      expected = [
        true
        false
      ];
    };
    test-and-anyOf-not = {
      expr = [
        (t (p.and [
          hostK
          (inst "h")
        ]) "host")
        (t (p.and [
          hostK
          (inst "h")
        ]) "host2")
        (t (p.anyOf [
          (kind "user")
          (kind "env")
        ]) "env")
        (t (p.not hostK) "host")
      ];
      expected = [
        true
        false
        true
        false
      ];
    };
  };
}
