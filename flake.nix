{
  description = "Nix package for LemMinX XML language server";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = {nixpkgs, ...}: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    formatter = {
      ${system} = pkgs.alejandra;
    };
    packages = {
      ${system}.default = pkgs.lemminx;
    };
    checks = {
      ${system} = {
        default = pkgs.lemminx;

        flake-format =
          pkgs.runCommand "lemminx-flake-format-check"
          {nativeBuildInputs = [pkgs.alejandra];}
          ''
            alejandra --check ${./flake.nix}
            touch $out
          '';

        package-metadata =
          pkgs.runCommand "lemminx-package-metadata-check"
          {}
          ''
            test "${pkgs.lib.getName pkgs.lemminx}" = "lemminx"
            touch $out
          '';
      };
    };
    devShells = {
      ${system}.default = pkgs.mkShell {
        packages = [pkgs.lemminx pkgs.maven pkgs.jdk];
      };
    };
  };
}
