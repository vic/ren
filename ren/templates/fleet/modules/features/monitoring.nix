# Monitoring: each db replica in a matching region is a prometheus scrape target on lb.
{ ren, lib, ... }:
let
  inherit (ren.lib) when;
in
{
  ren.kinds.db.zone = lib.types.str;
  ren.kinds.region.zone = lib.types.str;
  ren.kinds.replica = { db, region }: when (s: s.db.zone == s.region.zone) { };

  ren.db.primary.zone = "eu";
  ren.region.eu.zone = "eu";
  ren.replica.r1 = {
    db = ren.db.primary;
    region = ren.region.eu;
  };

  ren.channels.scrape = {
    fold = ren.lib.fold.list;
    type = lib.types.attrsOf lib.types.str; # each emission is checked when emitted
    at = ren.kinds.replica;
    to = _: ren.host.lb;
  };

  ren.aspects.replica-scrape = {
    at = ren.kinds.replica;
    scrape =
      {
        db,
        region,
        replica,
        ...
      }:
      {
        job = replica.name;
        target = "${db.zone}.${region.zone}:9090";
      };
  };
  ren.aspects.monitoring.nixos = { scrape, ... }: {
    # included only
    services.prometheus.scrapeConfigs = map (j: {
      job_name = j.job;
      static_configs = [ { targets = [ j.target ]; } ];
    }) scrape;
  };
}
