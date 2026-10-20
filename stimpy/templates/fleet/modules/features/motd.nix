# motd: every machine says "managed by ren"; motd-short is the included-only variant.
{ ren, ... }:
{
  ren.aspects.motd = {
    at = ren.kinds.machine;
    os.environment.etc.motd.text = "managed by ren"; # README.md#features
  };
  ren.aspects.motd-short = {
    os.environment.etc.motd.text = "ren"; # README.md#features
  }; # included only
}
