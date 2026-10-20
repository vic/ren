{ ren, lib }:
let
  inherit (import ../../fixtures/kinds.nix { inherit ren lib; })
    t
    kinds
    mk
    ok
    anInst
    ;
in
{
  kinds = {
    test-subkind-fields-transitive = {
      expr = builtins.attrNames kinds.guest.schema.options;
      expected = [
        "addr"
        "on"
        "settings"
      ];
    };
    test-below-not-inherited = {
      expr = [
        kinds.host.below
        kinds.guest.below
      ];
      expected = [
        [ "user" ]
        [ ]
      ];
    };
    test-listof-kind-check = {
      expr = (t.listOf kinds.host).check [ anInst ];
      expected = true;
    };
    test-subkind-check = {
      expr = [
        (kinds.machine.check anInst)
        (kinds.guest.check anInst)
      ];
      expected = [
        true
        false
      ];
    };
    test-list-field-of-kinds = {
      expr = map (g: g.name) ok.group.b.members;
      expected = [ "a" ];
    };
    test-submodule-default-filled = {
      expr = anInst.settings.kernel.channel;
      expected = null;
    };
    test-id-root = {
      expr =
        (mk {
          guest.g = {
            addr = "2";
            on = anInst;
          };
        }).guest.g.__id;
      expected = "machine:g";
    };
    # README.md#predicates `same a b`: identity is the gen-schema registry id_hash over kind + name
    test-same-id-hash =
      let
        two = mk {
          host.a.addr = "1";
          host.b.addr = "1";
        };
      in
      {
        expr = [
          (ren.predicates.same two.host.a two.host.b)
          (ren.predicates.same two.host.a two.host.a)
          (builtins.substring 0 5 two.host.a.id_hash)
        ];
        expected = [
          false
          true
          "host:"
        ];
      };
  };
}
