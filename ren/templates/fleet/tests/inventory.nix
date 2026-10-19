# #31: hosts from a JSON file (modules/hosts/_inventory.json); names map to refs, strings stay refused.
{
  lib,
  r,
  ev,
  ...
}:
let
  i = import ./_ids.nix;
  json = builtins.fromJSON (builtins.readFile ../modules/hosts/_inventory.json);
in
{
  # row: every JSON host is a host scope in its environment
  test-inventory-hosts-scoped = {
    expr = map (n: r.scopes ? "${i.prod}/host:${n}") (builtins.attrNames json);
    expected = [
      true
      true
    ];
  };
  # row: the JSON name became the ref (records read machine.addr through it)
  test-inventory-addr = {
    expr = r.pools.records.${i.prod}.web-2;
    expected = json.web-2.addr;
  };
  # row: a string where a ref belongs is refused (no coercion)
  test-inventory-string-ref-refused = {
    expr =
      (ev (
        { ren, ... }:
        {
          ren.host.web-9 = {
            environment = "prod";
            channel = ren.channel.stable;
            system = ren.system.x86_64-linux;
            addr = "10.0.1.19";
          };
        }
      )).scopes;
    expectedError.type = "ThrownError";
    expectedError.msg = "kind environment";
  };
}
