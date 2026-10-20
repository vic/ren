stimpy: {
  pred =
    let
      inherit (stimpy) lib;
      node = op: args: {
        __ren = {
          ref = "pred";
          inherit op args;
        };
      };

      match =
        ctx: p: s:
        let
          m = match ctx;
          r = p.__ren or (throw "ren: not a predicate");
        in
        if r.ref == "kind" then
          lib.elem r.kind s.__ren.kinds
        else if r.ref == "inst" then
          s.__ren.inst.__ren.id == r.id
        else if r.ref == "aspect" then
          ctx.activeAt r.name s
        else if r.ref == "scope" then
          s.__ren.id == r.id
        else if r.ref == "pred" then
          {
            and = lib.all (q: m q s) r.args;
            anyOf = lib.any (q: m q s) r.args;
            not = !(m r.args s);
            when = r.args s;
            within = lib.any (a: m r.args a) (ctx.ancestors s);
            has = lib.any (c: m r.args c) (ctx.children s);
          }
          .${r.op}
        else
          throw "ren: not a predicate";

      refsOf =
        p:
        let
          r = p.__ren or { };
          flip = map (x: x // { positive = !x.positive; });
        in
        if r.ref or null == "aspect" then
          [
            {
              aspect = r.name;
              positive = true;
            }
          ]
        else if r.ref or null != "pred" then
          [ ]
        else if r.op == "and" || r.op == "anyOf" then
          lib.concatMap refsOf r.args
        else if r.op == "not" then
          flip (refsOf r.args)
        else if r.op == "within" || r.op == "has" then
          refsOf r.args
        else
          [ ];
    in
    {
      and = node "and";
      anyOf = node "anyOf";
      not = node "not";
      # README.md#topology function kind: `when p { fields }` tags fields with the guard
      when =
        f:
        node "when" f
        // {
          __functor = self: fields: fields // { __guard = removeAttrs self [ "__functor" ]; };
        };
      within = node "within";
      has = node "has";
      inherit match refsOf;
      same = a: b: a.__ren.id == b.__ren.id;
      is =
        ctx: P: x:
        match ctx P (x.__ren.scope or (throw "ren: is: no scope on path for ${x.__ren.id or "?"}"));
    };
}
