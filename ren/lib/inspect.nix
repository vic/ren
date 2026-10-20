# inspect (#48, Ren only): the evaluated RESULT as a gen-inspect graph. Nodes are scope ids; edge
# labels: `child` (scope tree), a class name (class and channel forwards), a channel name (emitter
# -> receiver). `.render.mermaid .facts`, `.query "SELECT …"`, `.select`, `.why` are gen-inspect's.
ren: {
  inspect =
    r:
    let
      inherit (builtins) attrNames concatMap filter;
      inherit (ren.genLib) unique;
      nodes = attrNames r.scopes;
      parent = id: builtins.match "(.*)/[^/]*" id;
      tree = map (id: {
        label = "child";
        from = builtins.head (parent id);
        to = id;
      }) (filter (id: parent id != null) nodes);
      fwds = map (f: {
        label = f.class;
        inherit (f) from to;
      }) r.forwards;
      chans = concatMap (
        c:
        concatMap (
          e:
          map (to: {
            label = c;
            from = e;
            inherit to;
          }) r.channels.${c}.receivers.${e}
        ) r.channels.${c}.emitters
      ) (attrNames r.channels);
      edges = tree ++ fwds ++ chans;
    in
    ren.gen.inspect.fromGraph { kind = "scope"; } {
      inherit nodes;
      perLabel = builtins.listToAttrs (
        map (l: {
          name = l;
          value = id: map (e: e.to) (filter (e: e.label == l && e.from == id) edges);
        }) (unique (map (e: e.label) edges))
      );
    };
}
