# Web: nginx on the web hosts, each one a backend of haproxy in the same environment.
{ ren, ... }:
let
  inherit (ren.lib)
    and
    anyOf
    not
    when
    same
    ;
in
{
  # ══ CHANNELS — data (gen-aspects `channel`); at = emitters (default any), to = e: receivers ══
  ren.channels.backends = {
    fold = ren.lib.fold.list;
    at = ren.kinds.host;
    to =
      e:
      and [
        ren.kinds.host
        (when (r: same r.host.environment e.host.environment))
        (not e)
        (not ren.aspects.nginx)
      ];
  };

  # ══ ASPECTS — `at` activates; no `at` = only where included ═══════════
  ren.aspects.nginx = {
    # included only
    nixos.services.nginx.enable = true;
    tags = { ... }: "web";
    backends = { host, ... }: host.addr;
    persist = { ... }: "/var/lib/nginx";
  };
  ren.aspects.haproxy.nixos = { backends, lib, ... }: {
    services.haproxy.enable = true;
    services.haproxy.config = lib.concatMapStrings (a: "  server ${a} ${a}:80 check\n") backends;
  };
  ren.aspects.http-port = {
    at = and [
      ren.kinds.host
      ren.aspects.nginx
    ]; # an aspect ref = "active here"
    nixos.networking.firewall.allowedTCPPorts = [ 80 ];
  };

  # a VM test across two machines: client reaches nginx on web
  ren.aspects.web-check = {
    at = ren.system.x86_64-linux;
    nixosTest.web = {
      nodes.web.services.nginx.enable = true;
      nodes.web.networking.firewall.allowedTCPPorts = [ 80 ];
      nodes.client = { };
      testScript = ''
        start_all()
        web.wait_for_unit("nginx")
        client.wait_until_succeeds("curl -sf http://web/")
      '';
    };
  };

  # activator
  ren.aspects.web = {
    at = anyOf [
      ren.host.web-1
      ren.host.web-2
      ren.host.stage
    ];
    includes = [ ren.aspects.nginx ];
  };
}
