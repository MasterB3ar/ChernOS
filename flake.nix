{
  description = "ChernOS 2.0 – NixOS ISO + UI";

  inputs = {
    # NixOS 24.05 channel
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

    # Impermanence (optionally used later for persistence)
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
            ./hosts/chernos-iso/configuration.nix
          ];
        };
      };

      ########################################
      ## Expose ISO as a flake package
      ########################################
      # You can:
      #   nix build .#iso
      # or:
      #   nix build .#packages.x86_64-linux.iso
      packages.${system}.iso =
        self.nixosConfigurations.chernos-iso.config.system.build.isoImage;

      # Optional: make ISO the default package
      defaultPackage.${system} = self.packages.${system}.iso;
    };
}
