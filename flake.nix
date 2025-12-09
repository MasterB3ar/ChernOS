{
  description = "ChernOS 2.0 – XFCE live ISO";

  inputs = {
    # Stable NixOS 24.05
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

    # You can keep impermanence if you want later, but it is not used right now.
    impermanence.url = "github:nix-community/impermanence";
  };

  outputs = { self, nixpkgs, impermanence, ... }:
    let
      system = "x86_64-linux";
    in
    {
      # Main NixOS configuration for the ISO
      nixosConfigurations.chernos-iso = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/chernos-iso/configuration.nix
        ];
      };

      # Convenience attribute: nix build .#packages.x86_64-linux.iso
      packages.${system}.iso =
        self.nixosConfigurations.chernos-iso.config.system.build.isoImage;

      # Default package when you just do: nix build
      defaultPackage.${system} = self.packages.${system}.iso;
    };
}
