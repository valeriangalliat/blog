{ pkgs ? import <nixpkgs> {} }:

with pkgs; stdenv.mkDerivation {
  name = "blog";
  version = "0.1.0";
  src = ./.;
  buildInputs = [ nodejs ];
  buildPhase = "HOME=. npm install; make";
  installPhase = "cp -r public $out";
}
