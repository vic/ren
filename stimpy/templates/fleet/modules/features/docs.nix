# Docs: a mermaid map of the evaluated fleet (scope tree and class forwards), read from
# `ren.lib.result` in an `into` (stratum 3). Class docs at the root writes its own name: `docs`.
{ ren, ... }:
let
  inherit (builtins)
    concatStringsSep
    filter
    head
    match
    ;
  r = ren.lib.result;
  ids = builtins.attrNames r.scopes;
  node = id: "s${builtins.hashString "md5" id}";
  parent = id: match "(.*)/[^/]*" id;
  lines =
    map (id: "  ${node id}[\"${id}\"]") ids
    ++ map (id: "  ${node (head (parent id))} --- ${node id}") (filter (id: parent id != null) ids)
    ++ map (f: "  ${node f.from} -->|${f.class}| ${node f.to}") r.forwards;
in
{
  ren.classes.docs = {
    at = ren.kinds.fleet;
    into = _: _: { docs.mermaid = concatStringsSep "\n" ([ "flowchart TD" ] ++ lines) + "\n"; };
  };
}
