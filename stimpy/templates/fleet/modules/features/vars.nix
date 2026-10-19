# Vars: services declare the values they need generated; the fleet emits one plan (`vars`).
# A declaration at a host is per-machine; one at the fleet root is shared. Generating is a CLI job.
{ ren, ... }:
{
  ren.channels.generators = {
    fold = ren.lib.fold.attrs;
    to = _: ren.fleet.main; # no `at`: any scope emits
    into = { ... }: plan: { vars = plan; };
  };

  ren.aspects.ca = {
    at = ren.fleet.main;
    generators = { ... }: {
      shared.ca.files = [
        "ca.crt"
        "ca.key"
      ];
    };
  };
}
