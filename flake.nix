{
  description = "ChernOS v2.0.0 – Reactor Shell ISO";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    impermanence.url = "github:nix-community/impermanence";
  };

  # Helps on GitHub runners and on machines where flakes aren't enabled globally
  nixConfig = {
    extra-experimental-features = "nix-command flakes";
  };

  outputs = { self, nixpkgs, impermanence, ... }:
  let
    system = "x86_64-linux";
  in
  {
    nixosConfigurations.chernos-iso = nixpkgs.lib.nixosSystem {
      inherit system;

      modules = [
        # Base ISO module
        ({ ... }: {
          imports = [
            "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
          ];

# Base ISO module
({ lib, ... }: {
  imports = [
    "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  # ISO identity (override base module defaults)
  isoImage.isoName = lib.mkForce "ChernOS-v2.0.0-x86_64-linux.iso";
  isoImage.volumeID = lib.mkForce "CHERNOS_2_0_0";

  documentation.enable = false;
})

        # Impermanence provides environment.persistence.*
        impermanence.nixosModules.impermanence

        # Your actual OS config
        ./hosts/chernos-iso/configuration.nix
      ];
    };

    # Convenience build: nix build .#iso
    packages.${system}.iso =
      self.nixosConfigurations.chernos-iso.config.system.build.isoImage;

    defaultPackage.${system} = self.packages.${system}.iso;
  };
}
