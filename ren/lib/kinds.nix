# kinds: decl -> kind record (doubles as option type). `when P body` read as { __ren = "when"; pred; body; }.
ren: {
  kinds =
    let
      reserved = [
        "below"
        "spawns"
        "is"
      ];
      S = ren.gen.schema;
      nameOf = k: k.name;
      asOption = fv: if fv._type or null == "option" then fv else ren.genLib.mkOption { type = fv; };
      chainOf = kinds: k: [ k ] ++ (if kinds.${k}.is == null then [ ] else chainOf kinds kinds.${k}.is);
      rootOf =
        kinds: k: lib:
        lib.last (chainOf kinds k);
      # decl -> { fields; guard; own } without forcing any field type
      parse =
        kinds: decl:
        if builtins.isFunction decl then
          let
            r = decl (builtins.mapAttrs (n: _: kinds.${n}) (builtins.functionArgs decl));
            wrapped = r.__ren or null == "when";
          in
          {
            guard = if wrapped then r.pred else null;
            body = if wrapped then r.body else r;
            argFields = builtins.mapAttrs (n: _: kinds.${n}) (builtins.functionArgs decl);
          }
        else
          {
            guard = null;
            body = decl;
            argFields = { };
          };
    in
    {
      mkKinds =
        { lib, decls }:
        let
          kinds = builtins.mapAttrs mk decls;
          mk =
            n: decl:
            let
              p = parse kinds decl;
              isName = if p.body ? is then nameOf p.body.is else null;
              own = p.argFields // removeAttrs p.body reserved;
            in
            {
              __ren = "kind";
              name = n;
              below = map nameOf (p.body.below or [ ]);
              spawns =
                let
                  sp = p.body.spawns or { };
                  bad = builtins.filter (b: !(builtins.elem b (map nameOf (p.body.below or [ ])))) (
                    builtins.attrNames sp
                  );
                in
                if bad != [ ] then throw "ren: kind `${n}` spawns `${builtins.head bad}` not in below" else sp;
              is = isName;
              schema = schema.${n}; # gen-schema kind: own fields, `inherits` = `is`, guard = validator
              module = {
                options = builtins.mapAttrs (_: asOption) own;
                inherits = if isName == null then [ ] else [ isName ];
                # identity = kind mark + name: hashing never forces a (lazy, maybe cyclic) field value
                config._identity.keys = [ "name" ];
                validators = lib.optional (p.guard != null) (
                  S.mkValidator {
                    name = "ren-guard-${n}";
                    pred = p.guard.args;
                    message = "ren: instance of kind `${n}` violates its kind guard";
                  }
                );
              };
            }
            // (lib.mkOptionType {
              name = "ren-kind-${n}";
              description = "instance of ren kind ${n}";
              check = v: v.__ren or null == "instance" && builtins.elem n (chainOf kinds v.kind);
              merge =
                loc: defs:
                let
                  v = (lib.last defs).value;
                in
                if builtins.all (d: d.value.__id == v.__id) defs then
                  v
                else
                  throw "ren: conflicting definitions of ${lib.showOption loc}";
            })
            // {
              name = n;
            };
          schema = S.evalSchema { } [ { config.schema = builtins.mapAttrs (_: k: k.module) kinds; } ];
        in
        kinds;
    }
    // (ren.kindsCheck { inherit chainOf rootOf; });
}
