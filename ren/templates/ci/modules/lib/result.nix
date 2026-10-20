{ ren, lib }:
let
  # mini fleet (#48): `sys` at the box forwards into `top`; channel `reqs` (emitted at the box,
  # received at the root) forwards into `top`; class `docs` reads `ren.lib.result` for an output
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
          into = _: ms: { top = builtins.length ms; };
        };
        sys = {
          at = ren.kinds.box;
          into = _: _: { top = { }; };
        };
        docs = {
          at = ren.kinds.root;
          into = _: _: {
            docs = {
              scopes = builtins.attrNames ren.lib.result.scopes;
              inherit (ren.lib.result) forwards;
            };
          };
        };
      };
      ren.channels.reqs = {
        fold = ren.lib.fold.attrs;
        to = _: ren.root.r;
        into = _: pool: { top = pool; };
      };
      ren.aspects.a = {
        at = ren.kinds.box;
        reqs = { ... }: { x = 1; };
      };
    } (extra ren);
  ev = extra: ren.evalFleet { nixpkgs = { inherit lib; }; } (mini extra);
  r = ev (_: { });
in
{
  result = {
    test-result-readable-in-output = {
      expr = r.outputs.docs.scopes;
      expected = [
        "root:r"
        "root:r/box:b"
      ];
    };
    test-result-channels = {
      expr = r.channels;
      expected.reqs = {
        emitters = [ "root:r/box:b" ];
        receivers."root:r/box:b" = [ "root:r" ];
      };
    };
    # class forward (sys -> top) and channel forward (reqs -> top), in scope order of `from`
    test-result-forwards = {
      expr = r.outputs.docs.forwards;
      expected = [
        {
          class = "top";
          from = "root:r";
          to = "root:r";
        }
        {
          class = "top";
          from = "root:r/box:b";
          to = "root:r";
        }
      ];
    };
    # `outputs` stays behind the stratum-3 guarded `outputs` arg of `into`
    test-result-no-outputs = {
      expr =
        (ev (ren: {
          ren.classes.docs.into = _: _: { docs = ren.lib.result ? outputs; };
        })).outputs.docs;
      expected = false;
    };
    # negative control: deciding activation from the result is a cycle: an eval error, never a value
    test-result-read-in-at-refused = {
      expr =
        (ev (ren: {
          ren.aspects.a.at = if ren.lib.result.active.a == [ ] then ren.kinds.root else ren.kinds.box;
        })).active.a;
      expectedError.type = "EvalError";
      expectedError.msg = "infinite recursion encountered";
    };
  };
}
