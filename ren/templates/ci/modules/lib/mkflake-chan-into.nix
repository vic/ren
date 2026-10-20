{ ren, lib }:
let
  # mini fleet (README.md v35 channel vocabulary): a channel `into` key that names a class forwards
  # to the nearest ancestor-or-self scope with that class's branch; a channel key is refused.
  mini =
    extra:
    { ren, ... }:
    lib.recursiveUpdate {
      ren.kinds = {
        root.below = [ ren.kinds.box ];
        box = { };
      };
      ren.root.r = { };
      ren.box.b = { };
      ren.classes = {
        top = {
          at = ren.kinds.root;
          into = _: ms: { top = ms; }; # own name at the root: a top-level output
        };
        sys = {
          at = ren.kinds.box;
          into = { box, ... }: ms: { systems.${box.name} = ms; };
        };
      };
      ren.channels.reqs = {
        fold = ren.lib.fold.attrs;
        to = _: ren.root.r;
        into = _: pool: { top.inputs = pool; };
      };
      ren.aspects.a = {
        at = ren.kinds.root;
        reqs = { ... }: { x = 1; };
      };
    } (extra ren);
  out = extra: ren.mkFlake { nixpkgs = { inherit lib; }; } (mini extra);
  chan = name: into: ren: {
    ren.channels.${name} = {
      fold = ren.lib.fold.attrs;
      to = _: ren.root.r;
      inherit into;
    };
    ren.aspects.a.${name} = { ... }: { y = 1; };
  };
  loop2 = ren: {
    ren.classes.top.into = _: ms: { loop.n = builtins.length ms; };
    ren.channels.loop = {
      fold = ren.lib.fold.attrs;
      to = _: ren.root.r;
      into = _: pool: { top = pool; };
    };
  };
in
{
  mkflake-chan-into = {
    test-channel-forward-lands = {
      expr = (out (_: { })).top;
      expected = [ { inputs.x = 1; } ];
    };
    test-channel-forward-no-target = {
      expr = (out (chan "orphan" (_: pool: { sys = pool; }))).top;
      expectedError.type = "ThrownError";
      expectedError.msg = "channel `orphan` at .* forwards to `sys` but no scope has a `sys` branch";
    };
    test-channel-to-channel-refused = {
      expr = (out (chan "hop" (_: pool: { reqs = pool; }))).top;
      expectedError.type = "ThrownError";
      expectedError.msg = "channel `hop` into: key `reqs` names a channel; channel `hop` cannot emit to channel `reqs`";
    };
    test-class-channel-cycle-refused = {
      expr = (out loop2).top;
      expectedError.type = "ThrownError";
      expectedError.msg = "ren: stratum 3 cycle: class `top` -> channel `loop` -> class `top`";
    };
    # reading only `pools` names the cycle too
    test-class-channel-cycle-refused-pools = {
      expr = (ren.evalFleet { nixpkgs = { inherit lib; }; } (mini loop2)).pools.loop;
      expectedError.type = "ThrownError";
      expectedError.msg = "ren: stratum 3 cycle: class `top` -> channel `loop` -> class `top`";
    };
    # 3 hops through a class forward: top emits loop, loop forwards to sys, sys forwards to top
    test-class-forward-cycle-refused = {
      expr =
        (out (ren: {
          ren.classes.top.into = _: ms: { loop.n = builtins.length ms; };
          ren.classes.sys.into = _: ms: { top.n = builtins.length ms; };
          ren.channels.loop = {
            fold = ren.lib.fold.attrs;
            to = _: ren.box.b;
            into = _: pool: { sys = pool; };
          };
        })).top;
      expectedError.type = "ThrownError";
      expectedError.msg = "ren: stratum 3 cycle: class `sys` -> class `top` -> channel `loop` -> class `sys`";
    };
  };
}
