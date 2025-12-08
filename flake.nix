{
  description = "ChernOS 2.0 – NixOS ISO + UI";

  inputs = {
    # NixOS 24.05 channel
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

    # Impermanence (we can use later for persistence, but safe to keep here)
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
    nixosConfigurations.chernos-iso = lib.nixosSystem {
      inherit system;

      # If you want to pass flake inputs into modules later:
      specialArgs = {
        inherit impermanence;
      };

      modules = [
        ./hosts/chernos-iso/configuration.nix
      ];
    };

    ########################################
    ## Expose ISO as a flake package
    ########################################
    # So you can:
    #   nix build .#iso
    # or:
    #   nix build .#packages.x86_64-linux.iso
    packages.${system}.iso =
      self.nixosConfigurations.chernos-iso.config.system.build.isoImage;

    # Optional: make ISO the default package
    defaultPackage.${system} = self.packages.${system}.iso;

    ########################################
    ## (Optional) devShell for the UI project
    ########################################
    devShells.${system}.default = let
      pkgs = import nixpkgs { inherit system; };
    in pkgs.mkShell {
      buildInputs = with pkgs; [
        nodejs_22
        pnpm
        git
      ];
      shellHook = ''
        echo "ChernOS UI dev shell – run 'cd ui && pnpm install && pnpm dev'"
      '';
    };
  }
;
