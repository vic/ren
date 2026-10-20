# gen node for Ren instance `inst` under parent decls `p` ({ } at a root), rank `r` among siblings.
# decls carry the Ren scope; `seen` enforces once-per-path; `rank` rebuilds Ren's preorder.
ren: {
  scopesNode =
    isChain: argsOf: p: r: inst:
    let
      inherit (builtins)
        elem
        listToAttrs
        ;
      inherit (ren.gen.prelude) nameValuePair;
      parent = p.scope or null;
      pid = if parent == null then null else parent.__scope;
      id = (if pid == null then "" else pid + "/") + ren.gen.assemble.mkId inst.kind inst.name;
      fields = argsOf inst.kind; # README.md#scopes: function-kind arg fields only; no other field is forced
      bindings =
        (p.bindings or { })
        // listToAttrs (map (f: nameValuePair f inst.${f}) fields)
        // listToAttrs (map (k: nameValuePair k inst) (isChain inst.kind));
      scope = bindings // {
        __ren = "scope";
        __scope = id;
        inherit (inst) name kind;
        instance = inst;
        kinds = isChain inst.kind;
        parent = if parent == null then null else parent.instance // parent; # its fields too, as Stimpy's parent instance
      };
    in
    if elem inst.__id (p.seen or [ ]) then
      throw "ren: instance ${inst.__id} twice on path ${id}"
    else
      nameValuePair id {
        decls = {
          inherit scope bindings;
          seen = (p.seen or [ ]) ++ [ inst.__id ];
          rank = (p.rank or [ ]) ++ [ r ];
        };
      };
}
