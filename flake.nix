{
  description = "ChernOS v2.0.0 – Reactor Shell ISO";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    impermanence.url = "github:nix-community/impermanence";
  };

  outputs = { self, nixpkgs, impermanence, ... }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true; # chromium
    };
  in {
    nixosConfigurations.chernos-iso = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        ({ modulesPath, ... }: {
          imports = [
            # NixOS official minimal ISO base
            (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
            impermanence.nixosModules.impermanence
            ./hosts/chernos-iso/configuration.nix
          ];
        })
      ];
    };

    # Convenience: nix build .#packages.x86_64-linux.iso
    packages.${system}.iso =
      self.nixosConfigurations.chernos-iso.config.system.build.isoImage;

    # nix build
    defaultPackage.${system} = self.packages.${system}.iso;
  };
}
