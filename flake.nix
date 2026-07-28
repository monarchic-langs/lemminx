{
  description = "Nix package for LemMinX XML language server";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = {nixpkgs, ...}: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    formatter.${system} = pkgs.alejandra;
    packages.${system}.default = pkgs.lemminx;
    devShells.${system}.default = pkgs.mkShell {
      packages = [pkgs.lemminx pkgs.maven pkgs.jdk];
    };
  };
}
