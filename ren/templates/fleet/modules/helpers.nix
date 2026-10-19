# Option shorthands shared by every kind file (`ren.helpers`).
{ lib, ... }:
let
  opt = type: default: lib.mkOption { inherit type default; };
  maybe = type: opt (lib.types.nullOr type) null;
in
{
  ren.helpers = { inherit opt maybe; };
}
