{ ren, lib }:
let
  inherit (import ../../fixtures/activation.nix { inherit ren lib; })
    h
    u
    act
    kind
    na
    nb
    ;
in
{
  activation = {
    # a positive include cycle is legal: both active wherever either is
    test-positive-include-cycle = {
      expr =
        map
          (
            (act {
              a = na // {
                at = kind "host";
                includes = [ nb ];
              };
              b = nb // {
                includes = [ na ];
              };
            })
              "b"
          )
          [
            (h "db")
            (u "web-1")
            "env:prod"
          ];
      expected = [
        true
        true
        false
      ];
    };
    # a negative cycle through excludes has no well-founded verdict
    test-exclude-cycle-not-stratified = {
      expr =
        (act {
          a = na // {
            at = kind "host";
            excludes = [ nb ];
          };
          b = nb // {
            at = kind "host";
            excludes = [ na ];
          };
        })
          "a"
          (h "db");
      expectedError.type = "ThrownError";
      expectedError.msg = "ren: aspects not stratified: .*";
    };
  };
}
