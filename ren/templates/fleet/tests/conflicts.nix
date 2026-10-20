{ ev, ... }:
let
  # every host scope's `into` writes the top-level output probe-out.leaf = leaf host
  outLeaf =
    leaf:
    (ev (
      { ren, ... }:
      {
        ren.channels.probe-out = {
          fold = ren.lib.fold.list;
          at = ren.kinds.host;
          to = e: e;
          into = { host, ... }: _: { probe-out.leaf = leaf host; };
        };
        ren.aspects.probe-out = {
          at = ren.kinds.host;
          probe-out = { ... }: 1;
        };
      }
    )).outputs.probe-out.leaf;
  # two features emit attrsets into one attrs-folded channel, like `packages` (README.md#features)
  intoHello =
    a: b:
    (ev (
      { ren, ... }:
      {
        ren.channels.probe-pkgs = {
          fold = ren.lib.fold.attrs;
          at = ren.kinds.system;
          to = e: e;
          into = { system, ... }: p: { probe-pkgs.${system.name} = p; };
        };
        ren.aspects.probe-a = {
          at = ren.kinds.system;
          probe-pkgs = { ... }: { hello = a; };
        };
        ren.aspects.probe-b = {
          at = ren.kinds.system;
          probe-pkgs = { ... }: { hello = b; };
        };
      }
    )).outputs.probe-pkgs.x86_64-linux.hello;
in
{
  # control: equal leaves from many scopes merge (README.md#kinds top-level keys merge by `attrs`)
  test-output-merge-equal-leaf = {
    expr = outLeaf (_: "same");
    expected = "same";
  };
  # README.md#features, README.md#classes: two scopes writing different values at one output path is an error
  test-output-merge-conflict = {
    expr = outLeaf (h: h.name);
    expectedError.type = "ThrownError";
  };
  # control: two features that agree merge (README.md#features)
  test-into-attrs-equal-leaf = {
    expr = intoHello "a" "a";
    expected = "a";
  };
  # README.md#features, README.md#classes: two features giving different `hello` into one attrs pool is an error
  test-into-attrs-conflict = {
    expr = intoHello "a" "b";
    expectedError.type = "ThrownError";
  };
}
