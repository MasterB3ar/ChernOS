{
  description = "ChernOS 2.0 – NixOS ISO + UI";

  inputs = {
    # NixOS 24.05 channel (stable base)
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

    # Impermanence (optional, for persistence later)
    impermanence.url = "github:nix-community/impermanence";
  };

  outputs = { self, nixpkgs, impermanence, ... }:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;
    in
    {
      ########################################
      ## NixOS configuration for the ISO
      ########################################
      nixosConfigurations = {
        chernos-iso = lib.nixosSystem {
          inherit system;

          specialArgs = {
            inherit impermanence;
          };

          modules = [
            # 1) Standard NixOS graphical ISO with Calamares installer
            "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares.nix"

            # 2) Your custom ChernOS ISO config
            ./hosts/chernos-iso/configuration.nix
          ];
        };
      };

      ########################################
      ## Expose ISO as a flake package
      ########################################
      # Build with:
      #   nix build .#iso
      # or:
      #   nix build .#packages.x86_64-linux.iso
      packages.${system}.iso =
        self.nixosConfigurations.chernos-iso.config.system.build.isoImage;

      # Optional: makes `nix build .` build the ISO by default
      defaultPackage.${system} = self.packages.${system}.iso;
    };
}
