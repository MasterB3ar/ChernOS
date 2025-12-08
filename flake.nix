{
  description = "ChernOS 2.0 – NixOS-based reproducible ISO with kiosk UI";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
      in {
        packages.chernos-iso = pkgs.nixos.generateIsoImage {
          inherit system;
          modules = [
            ./hosts/chernos-iso/configuration.nix
          ];
        };

        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.nodejs_22
            pkgs.yarn
          ];
        };
      });
}
