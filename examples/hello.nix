{ pkgs ? import <nixpkgs> {} }:

pkgs.dockerTools.buildImage {
  name = "hello";
  content = pkgs.hello;
}
