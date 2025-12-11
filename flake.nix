{
  description = "ChernOS v2.0.0 – Reactor Shell ISO";

  inputs = {
    # NixOS 24.05 release
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

    # Persistence module
    impermanence.url = "github:nix-community/impermanence";
  };

  outputs = { self, nixpkgs, impermanence, ... }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
  in
  {
    ############################################################################
    # NixOS configuration: chernos-iso
    ############################################################################

    nixosConfigurations.chernos-iso = nixpkgs.lib.nixosSystem {
      inherit system;

      modules = [
        # ISO image module (gives us config.system.build.isoImage)
        ({ modulesPath, ... }: {
          imports = [
            (modulesPath + "/installer/cd-dvd/iso-image.nix")
          ];
        })

        # Impermanence: provides environment.persistence.*
        impermanence.nixosModules.impermanence

        # ChernOS system config
        ./hosts/chernos-iso/configuration.nix
      ];
    };

    ############################################################################
    # Packages / default
    ############################################################################

    # Convenience: nix build .#packages.x86_64-linux.iso
    packages.${system}.iso =
      self.nixosConfigurations.chernos-iso.config.system.build.isoImage;

    # So `nix build` (without attr) also builds the ISO
    defaultPackage.${system} = self.packages.${system}.iso;
  };
}
