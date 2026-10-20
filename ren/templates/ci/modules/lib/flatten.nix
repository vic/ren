# #59 `flatten args ms`: class content as one plain value for a config-only submodule.
{ ren, lib }:
let
  t = lib.types;
  # gen-merge `submodule` is shorthand-only, like nixpkgs `users.users.<n>`
  users = {
    options.users = lib.mkOption {
      type = t.attrsOf (
        t.submodule [
          {
            options.shell = lib.mkOption { type = t.str; };
            options.groups = lib.mkOption { type = t.listOf t.str; };
          }
        ]
      );
    };
  };
  # content as a class gets it: Ren args bound, the rest left to the module system
  ms = [
    (ren.content.classModule { user = "u"; } (
      { user, sh, ... }:
      {
        shell = "${sh}-${user}";
      }
    ))
    {
      _file = "f";
      key = "k";
      imports = [ { groups = [ "g" ]; } ];
    }
  ];
  args = {
    sh = "fish";
    lib = null;
  };
  eval =
    v:
    (lib.evalModules {
      modules = [
        users
        { users.u = v; }
      ];
    }).config.users.u;
in
{
  flatten = {
    test-flatten-into-config-only = {
      expr = eval (ren.flatten args ms);
      expected = {
        shell = "fish-u";
        groups = [ "g" ];
      };
    };
    # negative: the content modules as they arrive are not config
    test-flatten-raw-refused = {
      expr = eval (lib.mkMerge ms);
      expectedError.type = "ThrownError";
    };
  };
}
