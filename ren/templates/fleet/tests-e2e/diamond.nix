# e2e row: diamond - nginx reached through `web` and `status` lands once (README.md#aspects).
{ o, lib }:
let
  nixos = n: o.nixosConfigurations.${n}.config;
  count = x: l: builtins.length (lib.filter (y: y == x) l);
in
{
  # a list option: http-port's 80 once, and haproxy names web-1 once
  test-diamond-port-80-once = {
    expr = map (n: count 80 (nixos n).networking.firewall.allowedTCPPorts) [
      "web-1"
      "stage"
    ];
    expected = [
      1
      1
    ];
  };
  test-diamond-haproxy-web1-once = {
    expr = count "10.0.1.10" (
      lib.splitString " " (builtins.replaceStrings [ "\n" ] [ " " ] (nixos "lb").services.haproxy.config)
    );
    expected = 1;
  };
  test-diamond-status-vhost = {
    expr = (nixos "stage").services.nginx.virtualHosts ? status;
    expected = true;
  };
}
