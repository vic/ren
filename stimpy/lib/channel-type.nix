# Channel `type` (#30): an emission is checked when it is emitted; a channel with no `type` is unchecked.
# Full check, same depth as Ren: `type.check` plus a forced `lib.modules.mergeDefinitions`. A good value is delivered merged (submodule defaults apply).
stimpy: {
  typedEmission =
    c: ch: e:
    let
      who = if e ? n then "aspect `${e.n}`" else "class `${e.class}`";
      merged = stimpy.lib.modules.mergeDefinitions [ c ] ch.type [
        {
          file = who;
          value = e.v;
        }
      ];
      ok = ch.type.check e.v && (builtins.tryEval (builtins.deepSeq merged.mergedValue true)).success;
      # force the raw value first, so an error inside the content keeps its own message
      bad = builtins.seq (builtins.deepSeq e.v null) (
        throw "ren: ${who} at ${e.id} emits channel `${c}`: value is not of its `type`"
      );
    in
    if ch ? type then e // { v = if ok then merged.mergedValue else bad; } else e;
}
