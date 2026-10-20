# #59 `flatten args ms` (Ren: ren/templates/ci/modules/lib/flatten.nix)
{ lib, stimpy }:
let
  t = lib.types;
  # nixpkgs `submodule` is shorthand-only, like `users.users.<n>`
  users = {
    options.users = lib.mkOption {
      type = t.attrsOf (
        t.submodule {
          options.shell = lib.mkOption { type = t.str; };
          options.groups = lib.mkOption { type = t.listOf t.str; };
        }
      );
    };
  };
  # content as a class gets it (stimpy content.nix `wrap`): Ren args bound, the rest module args
  ms = [
    {
      _file = "f";
      key = "k";
      imports = [
        ({ sh, user, ... }: { shell = "${sh}-${user}"; })
        { groups = [ "g" ]; }
      ];
    }
  ];
  args = {
    sh = "fish";
    user = "u";
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
  test-flatten-into-config-only = {
    expr = eval (stimpy.flatten args ms);
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
  # #77: list content; the empty wrapper remainder is no `{ }` definition
  test-flatten-into-list = {
    expr =
      (lib.evalModules {
        modules = [
          { options.xs = lib.mkOption { type = t.listOf t.str; }; }
          {
            xs = stimpy.flatten { } [
              {
                _file = "f";
                imports = [ ({ ... }: [ "a" ]) ];
              }
            ];
          }
        ];
      }).config.xs;
    expected = [ "a" ];
  };
}
