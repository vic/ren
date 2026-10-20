# renArgs: what content fns and class/channel `into` receive at scope `id`.
# ruling: args = bindings (kind-named + instance-valued fields + parent's) // { parent; name } (README.md#channels `into = { <bindings>`); internal scope keys never leak
ren: {
  pipelineArgs =
    {
      lib,
      P,
      sc,
      pools,
      act,
      ctx,
    }:
    id:
    removeAttrs sc.scopes.${id} [
      "__ren"
      "__scope"
      "instance"
      "kinds"
      "kind"
    ]
    // lib.mapAttrs (_: f: f id) pools
    // {
      inherit lib;
      is = pr: x: P.isAt ctx { activeAt = act.active; } pr x id;
    };
}
