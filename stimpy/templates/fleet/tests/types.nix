# Channel `type` (#30): each emission is checked against the channel's type when it is emitted.
{ r, ev, ... }:
let
  i = import ./_ids.nix;
  badScrape =
    value:
    (ev (
      { ren, ... }:
      {
        ren.aspects.bad-scrape = {
          at = ren.kinds.replica;
          scrape = { ... }: value;
        };
      }
    )).pools.scrape.${i.lb};
  refused = value: {
    expr = builtins.deepSeq (badScrape value) null;
    expectedError.type = "ThrownError";
    expectedError.msg = "aspect `bad-scrape` at ${i.replica} emits channel `scrape`: value is not of its `type`";
  };
in
{
  # row: channel `type` - a good emission passes unchanged
  test-typed-scrape-good-emission-passes = {
    expr = r.pools.scrape.${i.lb};
    expected = [
      {
        job = "r1";
        target = "eu.eu:9090";
      }
    ];
  };
  # a nested field of the wrong type is refused (full check, not a shallow `attrs` check)
  test-typed-scrape-nested-bad-field-refused = refused {
    job = 1;
    target = "x";
  };
  # a value that is not an attrset is refused
  test-typed-scrape-non-attrs-refused = refused "x";
}
