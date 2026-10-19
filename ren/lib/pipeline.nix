# pipeline: kinds -> instances -> scopes -> activation -> landing/emissions/pools -> classes -> outputs.
# Every stage is lazy; pools, emissions and outputs are one fixpoint (renArgs reads pools and outputs).
ren: {
  pipeline =
    let
      K = ren.kinds;
      S = ren.scopes;
      P = ren.predicates;
      A = ren.activation;
      C = ren.content;
      L = ren.classes;
      out = ren.pipelineOut;
    in
    {
      lib,
      names,
      decl,
    }:
    let
      inherit (builtins) filter;
      kinds = K.mkKinds {
        inherit lib;
        decls = decl.kinds or { };
      };
      instances = K.mkInstances {
        inherit lib kinds;
        decls = lib.genAttrs names (k: decl.${k} or { });
      };
      sc = S.mkScopes { inherit kinds instances; };
      ctx = {
        data = id: sc.scopes.${id};
        parent = sc.parentOf;
        inherit (sc) children ancestors order;
        siblings = id: lib.remove id (sc.children (sc.parentOf id));
      };
      classes = decl.classes or { };
      channels = decl.channels or { };
      aspects = ren.pipelineAspects decl;
      act = A.mkActivation { inherit aspects ctx; };
      test = p: id: P.test ctx { activeAt = act.active; } p id;
      # ruling: a branch with `at` absent/null matches every scope, like a channel's default (fleet-ren.md:102)
      matches = b: id: (b.at or null) == null || test b.at id;
      inherit (ren.pipelineBranch (args // { inherit matches; })) branchAt branchIx;
      # receivers c e = scopes matching `to e`, e = the emitter's scope (fleet-ren.md:103)
      receivers = c: e: filter (test (channels.${c}.to sc.scopes.${e.path})) sc.order;
      # ruling: content's `is P x` tests x's scope on the current path (fleet-ren.md:113), so it is bound per scope id
      renArgs = ren.pipelineArgs {
        inherit
          lib
          P
          sc
          pools
          act
          ctx
          ;
      };
      inherit (o) pools;
      args = {
        inherit
          lib
          L
          C
          sc
          test
          channels
          classes
          branchAt
          renArgs
          act
          aspects
          ;
      };
      strata = ren.strata (args // { inherit matches; });
      o = out (args // { inherit strata receivers; });
    in
    {
      inherit
        kinds
        instances
        aspects
        test
        ;
      result = ren.pipelineResult (args // { inherit branchIx receivers o; });
    };
}
