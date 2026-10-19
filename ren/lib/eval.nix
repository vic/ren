# evalFleet: fleet module -> view -> pipeline -> RESULT (scopes active landed forwarded emitted pools branches outputs).
# ruling: the fleet is a module; `ren` = `_module.args.ren` (fleet.md:134,579), replacing the two-pass loader.
# ruling: module evaluation uses Gen's gen-merge (evalModuleTree); Ren depends on Gen only.
ren: {
  mkFlake = inputs: module: (ren.evalFleet inputs module).outputs;
  evalFleet =
    inputs: module:
    let
      lib = ren.genLib;
      inherit (ren) view;
      cfg =
        (lib.evalModules {
          modules = [
            view.module
            {
              _module.args = {
                inherit inputs;
                ren = world;
              };
            }
            module
          ];
        }).config.ren;
      names = builtins.attrNames cfg.kinds;
      insts = removeAttrs cfg view.declared;
      unknown = builtins.filter (k: !(cfg.kinds ? ${k})) (builtins.attrNames insts);
      p = ren.pipeline {
        inherit lib names;
        decl =
          if unknown != [ ] then throw "ren: instances of unknown kind `${builtins.head unknown}`" else cfg;
      };
      renLib = {
        inherit (ren)
          and
          anyOf
          not
          when
          within
          has
          same
          fold
          ;
        # ruling: `is P x` on a scope tests P at that scope (fleet-ren.md:467); an instance needs content's `is`
        is = P: x: if (x.__ren or null) == "scope" then p.test P x.__scope else ren.is P x;
      };
      # ruling: `ren.<kind>` exists for every declared kind (empty when it has no instances) (fleet-ren.md:95)
      world = p.instances // {
        lib = renLib;
        inherit (p) kinds;
        inherit (cfg) classes channels aspects; # declared aspects only: a ref never forces inline discovery
      };
    in
    p.result;
}
