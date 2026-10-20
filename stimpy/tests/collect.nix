{ lib, stimpy }:
let
  inherit (import ./_vocab.nix { inherit lib stimpy; })
    run
    realize
    err
    w
    n1
    p1
    ;
  # cfg at node collects `out`; hm at person forwards into cfg; tags channel into an output
  go =
    extra: aspects:
    run [
      (
        { ren, ... }:
        lib.recursiveUpdate {
          ren.classes = {
            cfg = {
              at = ren.kinds.node;
              into = { node, ... }: ms: { out.${node.name} = ms; };
            };
            hm = {
              at = ren.kinds.person;
              into = { parent, ... }: ms: { cfg.imports = ms; };
            };
          };
          ren.channels.tags = {
            fold = ren.lib.fold.list;
            to = _: ren.world.w;
            into = { ... }: vs: { tagList = vs; };
          };
          ren.aspects = aspects ren;
        } (extra ren)
      )
    ];
  out = r: n: realize r.outputs.out.${n};
in
{
  test-module-preapplied = {
    expr = out (go (_: { }) (ren: {
      a.at = ren.node.n1;
      a.cfg = { node, config, ... }: { out.name = node.name; };
    })) "n1";
    expected.name = "n1";
  };
  test-forward-to-ancestor =
    let
      r = go (_: { }) (ren: {
        a.at = ren.kinds.person;
        a.hm.out.home = 1;
      });
    in
    {
      expr = [
        (out r "n1")
        r.forwarded.cfg.${n1}
      ];
      expected = [
        { home = 1; }
        [ p1 ]
      ];
    };
  # a class writing an output key equal to its own name is an output, not a forward to itself
  test-own-name-key-is-output = {
    expr =
      (go
        (ren: {
          ren.classes.cfg.into = { ... }: _: { cfg.x = 1; };
        })
        (ren: {
          a.at = ren.node.n1;
          a.cfg = { };
        })
      ).outputs.cfg.x;
    expected = 1;
  };
  test-forward-no-target = {
    expr =
      (go (ren: {
        ren.classes.up = {
          at = ren.kinds.world;
          into = { ... }: ms: { cfg = { }; };
        };
      }) (_: { })).outputs;
    expectedError = err;
  };
  # into-emission feeds pool; README.md#channels channel into once per receiver
  test-into-emission-and-channel-into =
    let
      r = go (ren: {
        ren.classes.cfg.into = { node, ... }: ms: { tags = node.name; };
      }) (_: { });
    in
    {
      expr = [
        r.outputs.tagList
        r.emitted.tags
      ];
      expected = [
        [
          "n1"
          "n2"
          "v1"
        ]
        [
          "world:w/zone:z1/node:n1"
          "world:w/zone:z1/node:n2"
          "world:w/zone:z2/vm:v1"
        ]
      ];
    };
  test-pool-and-is-in-content = {
    expr = out (go (_: { }) (ren: {
      a.at = ren.kinds.node;
      a.tags = { node, ... }: node.name;
      b.at = ren.node.n1;
      b.cfg = { parent, ... }: { out.up = ren.lib.is ren.kinds.zone parent; };
      c.at = ren.world.w;
      c.tags = { ... }: "w";
    })) "n1";
    expected.up = true;
  };
  test-output-conflict = {
    expr =
      (go (ren: {
        ren.classes.cfg.into = { node, ... }: ms: { same.x = node.name; };
      }) (_: { })).outputs.same.x;
    expectedError = err;
  };
  test-outputs-read-ok = {
    expr =
      (go (ren: {
        ren.classes.rd = {
          at = ren.kinds.world;
          into = { outputs, ... }: ms: { seen = lib.attrNames outputs.out; };
        };
      }) (_: { })).outputs.seen;
    expected = [
      "n1"
      "n2"
      "v1"
    ];
  };
  test-stratum3-cycle = {
    expr =
      (go (ren: {
        ren.classes.rd = {
          at = ren.kinds.person;
          into = { outputs, ... }: ms: { cfg = { }; };
        };
      }) (_: { })).outputs;
    expectedError = err;
  };
  test-branches = {
    expr = (go (_: { }) (_: { })).branches.cfg.${n1};
    expected = 0;
  };
  test-world-receives = {
    expr =
      lib.attrNames
        (go (_: { }) (ren: {
          a.at = ren.world.w;
          a.tags = { ... }: 1;
        })).pools.tags;
    expected = [ w ];
  };
}
