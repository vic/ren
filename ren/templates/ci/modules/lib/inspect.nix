{ ren, lib }:
let
  # mini fleet (#48, Ren only): `sys` at the box forwards into `top` at the root; class `docs`
  # renders the fleet's own gen-inspect graph (`ren.lib.inspect`) as mermaid
  mini =
    { ren, ... }:
    {
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
          into = _: _: { docs = ren.lib.inspect.render.mermaid ren.lib.inspect.facts; };
        };
      };
    };
  r = ren.evalFleet { nixpkgs = { inherit lib; }; } mini;
  q = (ren.inspect r).query;
in
{
  inspect = {
    test-inspect-mermaid = {
      expr = map (s: lib.hasInfix s r.outputs.docs) [
        "root:r<br/>scope"
        "root:r/box:b<br/>scope"
        "root_r/box_b -->|top| root_r"
      ];
      expected = [
        true
        true
        true
      ];
    };
    test-inspect-query = {
      expr = q "SELECT src, dst FROM edge WHERE label = 'top'";
      expected = [
        {
          src = "root:r/box:b";
          dst = "root:r";
        }
      ];
    };
    # negative control: a label the graph does not have is refused by gen-inspect's door
    test-inspect-query-unknown-label = {
      expr = q "SELECT src FROM nope";
      expectedError.type = "ThrownError";
    };
  };
}
