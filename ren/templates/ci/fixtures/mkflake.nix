# Shared fixtures for the mkflake tests (not a test module).
{ ren, lib }:
rec {
  t = lib.types;
  opt = type: default: lib.mkOption { inherit type default; };
  sysOptions = {
    options = {
      peers = opt (t.listOf t.str) [ ];
      motd = opt t.str "";
      users = opt (t.attrsOf (t.submodule { options.shell = opt t.str "sh"; })) { };
    };
  };
  fleet =
    extra:
    { ren, lib, ... }:
    let
      inherit (ren.lib)
        and
        not
        when
        same
        ;
      inherit (ren.lib.fold) list;
    in
    {
      ren.classes = {
        sys = {
          at = ren.kinds.box;
          into =
            { box, ... }:
            ms: {
              systems.${box.name} = (lib.evalModules { modules = [ sysOptions ] ++ ms; }).config;
            };
        };
        home = {
          at = ren.kinds.person;
          # class values are modules: hand each to the submodule as a module, not as config
          into = { person, ... }: ms: { sys.users.${person.name} = lib.mkMerge (map (m: _: m) ms); };
        };
      };
      ren.kinds = {
        root.below = [ ren.kinds.zone ];
        zone = {
          below = [ ren.kinds.box ];
          spawns.box = s: lib.filterAttrs (_: b: same b.zone s.zone) ren.box;
        };
        box = {
          zone = ren.kinds.zone;
          below = [ ren.kinds.person ];
        };
        person = { };
      };
      ren.root.r = { };
      ren.zone.a = { };
      ren.zone.b = { };
      ren.box.b1.zone = ren.zone.a;
      ren.box.b2.zone = ren.zone.a;
      ren.box.b3.zone = ren.zone.b;
      ren.person.p = { };
      ren.channels.peers = {
        fold = list;
        at = ren.kinds.box;
        to =
          e:
          and [
            ren.kinds.box
            (when (r: same r.zone e.zone))
            (not e)
          ];
      };
      ren.aspects = {
        peer = {
          at = ren.kinds.box;
          peers = { box, ... }: box.name;
          sys = { peers, ... }: { inherit peers; };
        };
        motd = {
          at = ren.kinds.box;
          sys.motd = "hi";
        };
        short.sys.motd = "q";
        quiet = {
          at = when (s: s.box.name or "" == "b3");
          excludes = [ ren.aspects.motd ];
          includes = [ ren.aspects.short ];
        };
        shell = {
          at = ren.kinds.person;
          home.shell = "fish";
        };
      }
      // extra ren;
    };
  # module form (fleet.md:134): the fleet is a module, inputs carry the nixpkgs lib
  inputs.nixpkgs = { inherit lib; };
  run = extra: ren.mkFlake inputs (fleet extra);
  out = run (_: { });
  pick = s: { inherit (s) peers motd users; };
}
