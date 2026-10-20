# fleet.md v35: a channel `into` key naming a class forwards to the nearest ancestor-or-self scope
# with that class's branch; a channel key is refused; a class-channel cycle is refused by name
{ lib, stimpy }:
let
  inherit (import ./_vocab.nix { inherit lib stimpy; }) run err;
  go =
    extra:
    run [
      (
        { ren, ... }:
        lib.recursiveUpdate {
          ren.classes = {
            top = {
              at = ren.kinds.world; # own name at the root: a top-level output
              into = { ... }: ms: {
                top =
                  (lib.evalModules {
                    modules = ms ++ [ { options.inputs = lib.mkOption { type = lib.types.attrs; }; } ];
                  }).config.inputs;
              };
            };
            sys = {
              at = ren.kinds.node;
              into = { node, ... }: ms: { systems.${node.name} = ms; };
            };
          };
          ren.channels.reqs = {
            fold = ren.lib.fold.attrs;
            to = _: ren.world.w;
            into = { ... }: pool: { top.inputs = pool; };
          };
          ren.aspects.a = {
            at = ren.world.w;
            reqs = { ... }: { x = 1; };
          };
        } (extra ren)
      )
    ];
  chan = name: into: ren: {
    ren.channels.${name} = {
      fold = ren.lib.fold.attrs;
      to = _: ren.world.w;
      inherit into;
    };
    ren.aspects.a.${name} = { ... }: { y = 1; };
  };
  # top emits channel `loop`; loop (received at ren.<kind>.<name>) forwards to class `to`
  loop = kind: name: to: ren: {
    ren.classes.top.into = { ... }: ms: { loop.n = builtins.length ms; };
    ren.channels.loop = {
      fold = ren.lib.fold.attrs;
      to = _: ren.${kind}.${name};
      into = { ... }: pool: { ${to} = pool; };
    };
  };
in
{
  test-channel-forward-lands = {
    expr = (go (_: { })).outputs.top;
    expected.x = 1;
  };
  test-channel-forward-no-target = {
    expr = (go (chan "orphan" ({ ... }: pool: { sys = pool; }))).outputs.top;
    expectedError = err // {
      msg = "channel `orphan` at .* forwards to `sys` but no scope has a `sys` branch";
    };
  };
  test-channel-to-channel-refused = {
    expr = (go (chan "hop" ({ ... }: pool: { reqs = pool; }))).outputs.top;
    expectedError = err // {
      msg = "channel `hop` into: key `reqs` names a channel; channel `hop` cannot emit to channel `reqs`";
    };
  };
  test-class-channel-cycle-refused = {
    expr = (go (loop "world" "w" "top")).outputs.top;
    expectedError = err // {
      msg = "ren: stratum 3 cycle: class `top` -> channel `loop` -> class `top`";
    };
  };
  test-class-channel-cycle-refused-pools = {
    expr = (go (loop "world" "w" "top")).pools.loop;
    expectedError = err // {
      msg = "ren: stratum 3 cycle: class `top` -> channel `loop` -> class `top`";
    };
  };
  # 3 hops through a class forward: top emits loop, loop forwards to sys, sys forwards to top
  test-class-forward-cycle-refused = {
    expr =
      (go (
        ren:
        lib.recursiveUpdate (loop "node" "n1" "sys" ren) {
          ren.classes.sys.into = { ... }: ms: { top.n = builtins.length ms; };
        }
      )).outputs.top;
    expectedError = err // {
      msg = "ren: stratum 3 cycle: class `sys` -> class `top` -> channel `loop` -> class `sys`";
    };
  };
}
