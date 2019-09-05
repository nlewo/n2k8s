{ pkgs ? import (import ./nix/sources.nix).nixpkgs {} }:

pkgs.dockerTools.buildImage {
  name = "hello";
  contents = pkgs.hello;
}
