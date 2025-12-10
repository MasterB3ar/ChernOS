{
  description = "ChernOS v2.0.0 – reactor control ISO";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
  };

  outputs = { self, nixpkgs, ... }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
  in {
    # NixOS ISO configuration
    nixosConfigurations.chernos-iso = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        ./hosts/chernos-iso/configuration.nix
      ];
    };

    # Convenience: nix build .#packages.x86_64-linux.iso
    packages.${system}.iso =
      self.nixosConfigurations.chernos-iso.config.system.build.isoImage;

    # Convenience default: nix build
    defaultPackage.${system} = self.packages.${system}.iso;
  };
}
