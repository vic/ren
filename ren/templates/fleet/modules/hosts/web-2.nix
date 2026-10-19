# web-2 (from _inventory.json): the short motd.
{ ren, ... }:
{
  ren.aspects.quiet = {
    at = ren.host.web-2;
    excludes = [ ren.aspects.motd ];
    includes = [ ren.aspects.motd-short ];
  };
}
