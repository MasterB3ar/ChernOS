{
  description = "ChernOS v1.4.0 — Reactor Overdrive";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

  outputs = { self, nixpkgs }: let
    system = "x86_64-linux";
    lib    = nixpkgs.lib;
    pkgs   = import nixpkgs { inherit system; };

    # ---------- GRUB THEME ----------
    grubTheme = pkgs.runCommand "grub-theme-chernos" {} ''
      mkdir -p $out/share/grub/themes/chernos

      cat > $out/share/grub/themes/chernos/theme.txt <<EOF
terminal_output gfxterm
color_normal cfeecb 000000
color_highlight bff9a8 000000

menuentry "ChernOS v1.4.0 Live" {
  set gfxpayload=keep
}
EOF
    '';

    # ---------- PLYMOUTH THEME ----------
    plymouthTheme = pkgs.runCommand "plymouth-theme-chernos" {} ''
      mkdir -p $out/share/plymouth/themes/chernos

      cat > $out/share/plymouth/themes/chernos/chernos.plymouth <<EOF
[Plymouth Theme]
Name=ChernOS
Description=Nuclear green boot glow
ModuleName=script

[script]
ImageDir=/usr/share/plymouth/themes/chernos
ScriptFile=/usr/share/plymouth/themes/chernos/chernos.script
EOF

      cat > $out/share/plymouth/themes/chernos/chernos.script <<'EOF'
Window.SetBackgroundTopColor (0.0, 0.02, 0.01);
Window.SetBackgroundBottomColor (0.0, 0.0, 0.0);
EOF
    '';

    # ---------- Optional persistence helper ----------
    mountHelper = pkgs.writeShellScriptBin "chernos-persist-helper" ''
      set -eu

      if [ -e /dev/disk/by-label/CHERNOS_PERSIST ]; then
        mkdir -p /persist
        mount -o rw,noatime /dev/disk/by-label/CHERNOS_PERSIST /persist || true
        mkdir -p /persist/chernos-logs
        touch /persist/chernos-logs/.persist-ok || true
        echo "export CHERNOS_PERSIST=1" > /run/chernos-persist.env
      fi
    '';

    # ---------- ChernOS UI (HTML + JS) ----------
    # HTML is stored as a real file for easier editing:
    chernosPage = ./ui/index.html;

  in {
    nixosConfigurations.chernos-iso = lib.nixosSystem {
      inherit system;
      modules = [
        # Base ISO module
        "${nixpkgs}/nixos/modules/installer/cd-dvd/iso-image.nix"

        ({ pkgs, lib, ... }: {
          isoImage.isoName = "chernos-os.iso";


          # ---------- Boot stack ----------
          boot.loader.grub.enable  = lib.mkForce true;
          boot.loader.grub.version = 2;
          boot.loader.grub.device  = "nodev";
          boot.loader.grub.theme   = "${grubTheme}/share/grub/themes/chernos/theme.txt";

          boot.plymouth.enable        = true;
          boot.plymouth.themePackages = [ plymouthTheme ];
          boot.plymouth.theme         = "chernos";

          boot.kernelParams = [
            "quiet"
            "splash"
            "vt.global_cursor_default=0"
            "panic=10"
            "sysrq=0"
          ];

          # ---------- Silence noisy units on live ISO ----------
          services.logrotate.enable = false;
          systemd.services."logrotate-checkconf".enable              = false;
          systemd.services."systemd-journal-catalog-update".enable   = false;
          systemd.services."systemd-update-done".enable              = false;

          # ---------- Networking / SSH off for kiosk ----------
          networking.useDHCP                 = false;
          networking.networkmanager.enable   = false;
          systemd.services."systemd-networkd".enable = false;
          systemd.services."systemd-resolved".enable = false;
          systemd.services."sshd".enable              = false;

          # ---------- Rendering ----------
          hardware.opengl.enable = true;
          environment.variables = {
            WLR_RENDERER_ALLOW_SOFTWARE = "1";
            WLR_NO_HARDWARE_CURSORS     = "1";  # helps with VM cursor lag
          };

          # ---------- Display: Wayland / Sway kiosk ----------
          services.xserver.enable = false;
          programs.sway.enable    = true;

          # ---------- kiosk user ----------
          users.users.kiosk = {
            isNormalUser = true;
            password     = "kiosk";
            extraGroups  = [ "video" "input" ];
          };

          # ---------- Optional persistence service ----------
          systemd.services.chernos-persist = {
            wantedBy = [ "multi-user.target" ];
            after    = [ "local-fs.target" "systemd-udev-settle.service" ];
            serviceConfig = {
              Type      = "oneshot";
              ExecStart = "${mountHelper}/bin/chernos-persist-helper";
              RemainAfterExit = true;
            };
          };

          systemd.tmpfiles.rules = [
            "d /persist 0755 root root -"
          ];

          # ---------- /etc/chernos-kiosk.sh (Chromium launcher) ----------
          environment.etc."chernos-kiosk.sh" = {
            mode = "0755";
            text = ''
              #!/bin/sh
              # Optional persistence marker
              if [ -f /run/chernos-persist.env ]; then
                . /run/chernos-persist.env
              fi

              URL="file://${chernosPage}"
              if [ "x$CHERNOS_PERSIST" = "x1" ]; then
                URL="$URL?persist=1"
              fi

              exec ${pkgs.chromium}/bin/chromium \
                --enable-features=UseOzonePlatform \
                --ozone-platform=wayland \
                --kiosk "$URL" \
                --incognito \
                --start-fullscreen \
                --noerrdialogs \
                --disable-translate \
                --overscroll-history-navigation=0
            '';
          };

          # ---------- greetd → sway → Chromium kiosk ----------
          services.greetd.enable = true;
          services.greetd.settings = {
            terminal.vt = 1;
            default_session = {
              command = "${pkgs.sway}/bin/sway";
              user    = "kiosk";
            };
          };

          # Disable extra TTYs
          systemd.services."getty@tty2".enable = false;
          systemd.services."getty@tty3".enable = false;
          systemd.services."getty@tty4".enable = false;
          systemd.services."getty@tty5".enable = false;
          systemd.services."getty@tty6".enable = false;

          # Tools on the ISO
          environment.systemPackages = with pkgs; [
            chromium
            swaybg
            vim
          ];

          # ---------- sway config: call kiosk script ----------
          environment.etc."sway/config".text = ''
            set $mod Mod4

            # Prevent exit
            bindsym $mod+Shift+e exec echo "exit blocked"

            # Launch ChernOS kiosk helper script
            exec /etc/chernos-kiosk.sh
          '';
        })
      ];
    };

    # Build ISO with: nix build .#iso
    packages.${system}.iso =
      self.nixosConfigurations.chernos-iso.config.system.build.isoImage;
  };
}
