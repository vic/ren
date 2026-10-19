# Content values (A6), module wrapping, landing check, channel pools. Inputs abstract.
ren: {
  content =
    let
      xml = f: builtins.toXML f;
      isContentFn = f: builtins.isFunction f && builtins.match ".*<attrspat.*" (xml f) != null;
      isBare = f: builtins.isFunction f && !isContentFn f;
      bare = throw "ren: bare function emission; wrap it in `{ ... }:`";
      asModule =
        renArgs: v:
        # gen-bind binds a content fn, or the fns in a class value's deferredModule `imports`
        if isBare v then bare else (ren.gen.bind.wrap { bindings = renArgs; } v).module;
      # class content: the class's module system gives `lib`; Ren's never wins there (#20, as Stimpy)
      classModule = renArgs: asModule (removeAttrs renArgs [ "lib" ]);
      callContent = renArgs: v: if builtins.isFunction v then (asModule renArgs v) { } else v;
      # aspect = { name; content = { key = value; }; }; result = { key = [ scope ids ]; }
      landing =
        {
          keyKind,
          classMatches,
          channelMatches,
        }:
        aspect: scopes:
        builtins.mapAttrs (
          k: _:
          let
            kind = keyKind k;
            ids =
              if kind == "class" then
                builtins.filter (classMatches k) scopes
              else if kind == "channel" then
                builtins.filter (channelMatches k) scopes
              else
                throw "ren: aspect `${aspect.name}`: key `${k}` is neither class nor channel";
          in
          if ids == [ ] then
            throw "ren: aspect `${aspect.name}`: key `${k}` lands in none of its scopes"
          else
            ids
        ) aspect.content;
      mkPools =
        {
          channels,
          emissions,
          receivers,
        }:
        order:
        let
          pos = builtins.listToAttrs (
            ren.gen.prelude.imap0 (i: id: ren.gen.prelude.nameValuePair id i) order
          );
          # folds see emissions in scope traversal order (fleet.md:444); sort is stable within a scope
          inOrder = builtins.sort (a: b: pos.${a.path} < pos.${b.path});
        in
        builtins.mapAttrs (
          c: ch: id:
          ch.fold.apply c (inOrder (builtins.filter (e: builtins.elem id (receivers c e)) emissions.${c}))
        ) channels;
    in
    {
      inherit
        callContent
        isContentFn
        isBare
        bare
        mkPools
        landing
        asModule
        classModule
        ;
    };
}
