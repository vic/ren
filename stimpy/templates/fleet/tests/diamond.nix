# row: diamond - `web` and `status` both include nginx (README.md#aspects): it lands once per scope
{
  lib,
  r,
  ev,
  ...
}:
let
  i = import ./_ids.nix;
  count = x: l: builtins.length (lib.filter (y: y == x) l);
in
{
  test-diamond-nginx-landed-once = {
    expr = map (id: count "nginx" r.landed.nixos.${id}) [
      i.web1
      i.stage
    ];
    expected = [
      1
      1
    ];
  };
  # both includers are active on web-1 and stage
  test-diamond-both-paths-active = {
    expr =
      map
        (
          a:
          lib.all (id: lib.elem id r.active.${a}) [
            i.web1
            i.stage
          ]
        )
        [
          "web"
          "status"
        ];
    expected = [
      true
      true
    ];
  };
  # a list fold gets web-1's nginx emission exactly once
  test-diamond-backends-web1-once = {
    expr = count "10.0.1.10" r.pools.backends.${i.lb};
    expected = 1;
  };
  # the Den shape (1 host, N users): an aspect included by the host and by every user lands once
  # on the host; its nixos never lands at a user scope
  test-diamond-host-and-users = {
    expr =
      let
        x = ev (
          { ren, ... }:
          {
            ren.aspects.stage-users = {
              at = ren.lib.and [
                ren.kinds.user
                (ren.lib.within ren.host.stage)
              ];
              includes = [ ren.aspects.nginx ];
            };
          }
        );
      in
      [
        (count "nginx" x.landed.nixos.${i.stage})
        (count "nginx" (x.landed.nixos.${i.user i.stage "alice"} or [ ]))
      ];
    expected = [
      1
      0
    ];
  };
}
