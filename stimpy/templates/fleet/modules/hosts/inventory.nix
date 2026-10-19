# Inventory: the web hosts come from data (_inventory.json); names become refs.
{ ren, ... }:
{
  ren.host = builtins.mapAttrs (
    _: h:
    h
    // {
      environment = ren.environment.${h.environment};
      channel = ren.channel.${h.channel};
      system = ren.system.${h.system};
    }
  ) (builtins.fromJSON (builtins.readFile ./_inventory.json));
}
