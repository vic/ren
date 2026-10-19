# Channel `type` (#30): an emission is checked when it is emitted; a channel with no `type` is unchecked.
# Full check, same depth as Stimpy: `type.check` plus a forced gen-merge `type.merge` (genLib mergeDefinitions). A good value is delivered merged (submodule defaults apply).
ren: {
  typedEmission =
    c: ch: e:
    let
      who = if e ? n then "aspect `${e.n}`" else "class `${e.class}`";
      merged = ren.genLib.modules.mergeDefinitions [ c ] ch.type [
        {
          file = who;
          inherit (e) value;
        }
      ];
      ok = ch.type.check e.value && (builtins.tryEval (builtins.deepSeq merged.mergedValue true)).success;
      # force the raw value first, so an error inside the content keeps its own message
      bad = builtins.seq (builtins.deepSeq e.value null) (
        throw "ren: ${who} at ${e.path} emits channel `${c}`: value is not of its `type`"
      );
    in
    if ch ? type then e // { value = if ok then merged.mergedValue else bad; } else e;
}
