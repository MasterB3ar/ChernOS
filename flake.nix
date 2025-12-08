{
  description = "ChernOS 2.0 – NixOS ISO + UI (Sway/Chromium kiosk)";

  inputs = {
    # You can switch to another channel if you want (e.g. nixos-24.11).
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

    # For persistence v3 (profiles, states, logs).
    impermanence.url = "github:nix-community/impermanence";
  };

  outputs = { self, nixpkgs, impermanence, ... }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true; # Chromium, fonts, etc.
    };
  in {
    # NixOS ISO configuration
    nixosConfigurations.chernos-iso = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit self;
      };
      modules = [
        ./hosts/chernos-iso/configuration.nix
        impermanence.nixosModules.impermanence
      ];
    };

    # Simple dev shell for the UI (inside ui/)
    devShells.${system}.ui = pkgs.mkShell {
      name = "chernos-ui-dev";

      buildInputs = with pkgs; [
        nodejs_22
        pnpm
        git
      ];

      shellHook = ''
        echo "ChernOS UI dev shell"
        echo "cd ui/ && pnpm install && pnpm dev"
      '';
    };
  };
}
