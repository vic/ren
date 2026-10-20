# Status page: a second path to the shared nginx. `web` and `status` both include it on web-1
# and stage (a diamond); nginx lands once per scope (README.md#aspects).
{ ren, ... }:
{
  ren.aspects.status = {
    at = ren.lib.anyOf [
      ren.host.web-1
      ren.host.stage
    ];
    includes = [ ren.aspects.nginx ];
    nixos.services.nginx.virtualHosts.status.locations."/".return = "200 ok";
  };
}
