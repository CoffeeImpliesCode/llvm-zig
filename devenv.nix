{ pkgs, lib, config, inputs, ... }:
let
  pkgs-unstable = import inputs.nixpkgs-unstable { system = pkgs.stdenv.system; };
in rec {
  packages = (with pkgs; [
    llvmPackages_21.llvm
    llvmPackages_21.libclang
  ]) ++
  (with pkgs-unstable; [
    zig_0_16
  ]);

  env = {
    LD_LIBRARY_PATH = "${pkgs.lib.makeLibraryPath packages}";
    INCLUDE_DIRECTORIES = "${pkgs.lib.makeIncludePath packages}";
    ZIG_GLOBAL_CACHE_DIR = ".zig-cache/";
  };

  enterShell = ''
  '';

  scripts.gate.exec = "zig-gate";
}
