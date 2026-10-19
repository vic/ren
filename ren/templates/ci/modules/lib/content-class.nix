{ ren, ... }:
let
  # a class content fn called the way its module system calls it, with the class's `lib`
  call =
    renArgs:
    (ren.content.classModule renArgs (
      { lib, host, ... }: [
        lib
        host
      ]
    ))
      { lib = "class"; };
in
{
  content-class = {
    # #20: class content sees the class module system's lib; Ren's `lib` never wins there
    test-class-module-lib-is-class-lib = {
      expr = call {
        lib = "ren";
        host = 1;
      };
      expected = [
        "class"
        1
      ];
    };
    # control: the other Ren bindings still fill the content's formals
    test-class-module-binds-ren-args = {
      expr = call { host = 2; };
      expected = [
        "class"
        2
      ];
    };
  };
}
