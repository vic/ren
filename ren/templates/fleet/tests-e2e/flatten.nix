# #59: class content into a config-only submodule (`users.users.<n>`) through `ren.lib.flatten`.
{ inputs }:
let
  # an `account` class on users of metal hosts writes its content into users.users.<user>
  probe =
    put:
    { ren, ... }:
    {
      ren.classes.account = {
        at = ren.lib.and [
          ren.kinds.user
          (ren.lib.within ren.helpers.metal)
        ];
        into =
          { user, ... }:
          ms: {
            nixos =
              { lib, ... }@args:
              {
                users.users.${user.name} = put ren lib args ms;
              };
          };
      };
      ren.aspects.probe-account = {
        at = ren.kinds.user;
        account = { lib, ... }: {
          description = lib.concatStrings [
            "fl"
            "at"
          ];
        };
      };
      ren.aspects.probe-groups = {
        at = ren.kinds.user;
        account.extraGroups = [ "probe" ];
      };
    };
  alice =
    put:
    let
      o = inputs.impl.lib.mkFlake inputs {
        imports = [
          (inputs.import-tree ../modules)
          (probe put)
        ];
      };
      u = o.nixosConfigurations.lb.config.users.users.alice;
    in
    {
      inherit (u) description;
      probe = builtins.elem "probe" u.extraGroups;
    };
in
{
  # row: flattened content (a content fn with the class `lib`, and a plain value) lands as config
  test-flatten-users-users = {
    expr = alice (ren: _: ren.lib.flatten);
    expected = {
      description = "flat";
      probe = true;
    };
  };
  # negative: the content modules as they arrive: "The option `users.users.alice.imports' does not exist"
  test-flatten-raw-refused = {
    expr = alice (
      _: lib: _:
      lib.mkMerge
    );
    expectedError.type = "ThrownError";
  };
}
