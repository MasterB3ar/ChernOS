{
  description = "ChernOS v2.0.0 - Reactor Overdrive";

  # NixOS 24.05 input. flake.lock pins the exact revision + narHash.
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

  outputs = { self, nixpkgs }: let
    system  = "x86_64-linux";
    lib     = nixpkgs.lib;
    pkgs    = import nixpkgs { inherit system; };
    version = "2.0.0";

    # ---------- GRUB THEME ----------
    grubTheme = pkgs.runCommand "grub-theme-chernos" {} ''
      mkdir -p $out/share/grub/themes/chernos

      cat > $out/share/grub/themes/chernos/theme.txt <<EOF
terminal_output gfxterm
color_normal cfeecb 000000
color_highlight bff9a8 000000

menuentry "ChernOS v${version} Live" {
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

    # ---------- Persistence + overlayfs setup ----------
    persistSetup = pkgs.writeShellScriptBin "chernos-persist-setup" ''
      set -eu

      DEV="/dev/disk/by-label/CHERNOS_PERSIST"

      # Give udev a moment to populate /dev/disk/by-label (optional device)
      for i in 1 2 3 4 5; do
        [ -e "$DEV" ] && break
        sleep 0.2
      done

      if [ ! -e "$DEV" ]; then
        exit 0
      fi

      mkdir -p /persist
      if ! mountpoint -q /persist; then
        mount -o rw,noatime "$DEV" /persist || exit 0
      fi

      mkdir -p /persist/overlay /run/chernos-lower

      # Ensure base dirs exist (lower dirs)
      mkdir -p /home/kiosk
      mkdir -p /var/lib/chernos
      mkdir -p /var/log/chernos

      setup_overlay() {
        NAME="$1"
        TARGET="$2"
        LOWER_SRC="$3"

        mkdir -p "/persist/overlay/$NAME/upper" "/persist/overlay/$NAME/work" "/run/chernos-lower/$NAME"

        # Bind-mount the current (lower) view somewhere stable.
        if ! mountpoint -q "/run/chernos-lower/$NAME"; then
          mount --bind "$LOWER_SRC" "/run/chernos-lower/$NAME"
        fi

        # Permissions: kiosk must be able to write its upperdir.
        if [ "$NAME" = "home-kiosk" ]; then
          chown -R kiosk:kiosk "/persist/overlay/$NAME/upper" "/persist/overlay/$NAME/work" || true
        fi

        if ! mountpoint -q "$TARGET"; then
          mount -t overlay overlay -o "lowerdir=/run/chernos-lower/$NAME,upperdir=/persist/overlay/$NAME/upper,workdir=/persist/overlay/$NAME/work" "$TARGET"
        fi
      }

      setup_overlay "home-kiosk"       "/home/kiosk"       "/home/kiosk"
      setup_overlay "varlib-chernos"   "/var/lib/chernos"  "/var/lib/chernos"
      setup_overlay "varlog-chernos"   "/var/log/chernos"  "/var/log/chernos"

      # Marker for kiosk launcher.
      echo "export CHERNOS_PERSIST=1" > /run/chernos-persist.env
    '';

    # ---------- ChernOS UI (offline, bundled Tailwind) ----------
    chernosUI = pkgs.stdenvNoCC.mkDerivation {
      pname = "chernos-ui";
      version = version;
      src = ./ui;

      nativeBuildInputs = [ (if pkgs ? tailwindcss then pkgs.tailwindcss else pkgs.nodePackages.tailwindcss) ];

      buildPhase = ''
        set -eu

        cp $src/index.html ./index.html

        cat > input.css <<'CSS'
@tailwind base;
@tailwind components;
@tailwind utilities;
CSS

        tailwindcss -i input.css -o tailwind.css --content index.html --minify

        substituteInPlace index.html \
          --replace '<script src="https://cdn.tailwindcss.com"></script>' \
                    '<link rel="stylesheet" href="./tailwind.css">'
      '';

      installPhase = ''
        mkdir -p $out
        cp index.html tailwind.css $out/
      '';
    };

  in {
    nixosConfigurations.chernos-iso = lib.nixosSystem {
      inherit system;
      modules = [
        # Base ISO module
        "${nixpkgs}/nixos/modules/installer/cd-dvd/iso-image.nix"

        ({ pkgs, lib, ... }: {
          isoImage.isoName = "chernos-os.iso";

          # Pin NixOS option semantics for reproducibility and to avoid warnings.
          system.stateVersion = "24.05";

          # ---------- Fast boot + quiet ----------
          # The ISO module defines a loader timeout as well; force ours so the
          # build does not fail with conflicting definitions.
          boot.loader.timeout      = lib.mkForce 0;
          boot.loader.grub.enable  = lib.mkForce true;
          boot.loader.grub.device  = "nodev";
          boot.loader.grub.theme   = "${grubTheme}/share/grub/themes/chernos/theme.txt";

          boot.initrd.verbose    = false;
          boot.consoleLogLevel  = 0;
          boot.kernelModules    = [ "overlay" ];

          boot.kernelParams = [
            "quiet"
            "splash"
            "loglevel=3"
            "udev.log_level=3"
            "rd.udev.log_level=3"
            "systemd.show_status=0"
            "rd.systemd.show_status=0"
            "vt.global_cursor_default=0"
            "panic=10"
            "sysrq=0"
          ];

          systemd.extraConfig = ''
            DefaultTimeoutStartSec=10s
            DefaultTimeoutStopSec=10s
          '';

          # Disable noisy/slow one-shots (live ISO kiosk)
          services.logrotate.enable = false;
          systemd.services."logrotate-checkconf".enable            = false;
          systemd.services."systemd-journal-catalog-update".enable = false;
          systemd.services."systemd-update-done".enable            = false;
          systemd.services."systemd-udev-settle".enable            = false;
          systemd.services."systemd-timesyncd".enable              = false;

          services.journald.extraConfig = ''
            Storage=volatile
            RuntimeMaxUse=32M
            ForwardToConsole=no
          '';

          # ---------- Plymouth ----------
          boot.plymouth.enable        = true;
          boot.plymouth.themePackages = [ plymouthTheme ];
          boot.plymouth.theme         = "chernos";

          # ---------- Networking ----------
          # Calamares + nixos-install are dramatically more reliable with networking available.
          # (You can still keep the kiosk UI offline at the app layer.)
          networking.networkmanager.enable = true;
          # DHCP is handled by NetworkManager (do not set networking.useDHCP here).
          # Keep ssh off by default on the live ISO.
          systemd.services."sshd".enable  = false;

          # ---------- Audio (required for background music) ----------
          sound.enable = true;
          security.rtkit.enable = true;
          services.pipewire = {
            enable = true;
            pulse.enable = true;
            alsa.enable = true;
            alsa.support32Bit = true;
            wireplumber.enable = true;
          };

          # ---------- DBus (required by PipeWire session manager) ----------
          services.dbus.enable = true;

          # ---------- Rendering ----------
          hardware.opengl.enable = true;
          environment.variables = {
            WLR_RENDERER_ALLOW_SOFTWARE = "1";
            WLR_NO_HARDWARE_CURSORS     = "1";  # helps with VM cursor lag
          };

          # ---------- Display: Wayland / Sway kiosk ----------
          services.xserver.enable = false;
          programs.sway.enable    = true;

          # Calamares needs these even on a minimal ISO (device discovery + power info)
          services.udisks2.enable = true;
          services.upower.enable  = true;

          # ---------- kiosk user ----------
          users.users.kiosk = {
            isNormalUser = true;
            password     = "kiosk";
            extraGroups  = [ "video" "input" "audio" "wheel" "networkmanager" ];
          };

          # ---------- sudo (needed to launch Calamares as root from the kiosk session) ----------
          security.sudo.enable = true;
          security.sudo.extraConfig = ''
            Defaults env_keep += "WAYLAND_DISPLAY XDG_RUNTIME_DIR DISPLAY DBUS_SESSION_BUS_ADDRESS XAUTHORITY"
          '';

          # Allow the kiosk user to run Calamares without a password (GUI installer on a live ISO).
          security.sudo.extraRules = [
            {
              users = [ "kiosk" ];
              commands = [
                {
                  command = "${pkgs.calamares}/bin/calamares";
                  options = [ "NOPASSWD" "SETENV" ];
                }
              ];
            }
          ];

          # ---------- Real persistence (overlayfs) ----------
          systemd.services.chernos-persist = {
            description = "ChernOS persistence overlay setup";
            wantedBy    = [ "multi-user.target" ];
            after       = [ "local-fs.target" ];
            before      = [ "greetd.service" ];
            serviceConfig = {
              Type = "oneshot";
              ExecStart = "${persistSetup}/bin/chernos-persist-setup";
              RemainAfterExit = true;
            };
          };

          systemd.tmpfiles.rules = [
            "d /persist 0755 root root -"
            "d /var/lib/chernos 0755 root root -"
            "d /var/log/chernos 0755 root root -"
          ];

          # ---------- /etc/chernos-kiosk.sh (Chromium launcher) ----------
          environment.etc."chernos-kiosk.sh" = {
            mode = "0755";
            text = ''
              #!/bin/sh
              set -eu

              # Optional persistence marker
              if [ -f /run/chernos-persist.env ]; then
                . /run/chernos-persist.env
              fi

              # Ensure audio stack is running + unmuted (ISO kiosk reliability)
              export XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
              mkdir -p "$XDG_RUNTIME_DIR" 2>/dev/null || true

              # Try systemd user services first (if available)
              if command -v systemctl >/dev/null 2>&1; then
                systemctl --user start pipewire pipewire-pulse wireplumber 2>/dev/null || true
              fi

              # Fallback: spawn daemons if user services did not start
              if ! pgrep -u "$(id -u)" -x pipewire >/dev/null 2>&1; then
                ${pkgs.pipewire}/bin/pipewire >/tmp/pipewire.log 2>&1 &
              fi
              if ! pgrep -u "$(id -u)" -x pipewire-pulse >/dev/null 2>&1; then
                ${pkgs.pipewire}/bin/pipewire-pulse >/tmp/pipewire-pulse.log 2>&1 &
              fi
              if ! pgrep -u "$(id -u)" -x wireplumber >/dev/null 2>&1; then
                ${pkgs.wireplumber}/bin/wireplumber >/tmp/wireplumber.log 2>&1 &
              fi

              # Unmute + set sane volume
              ${pkgs.alsa-utils}/bin/amixer -q sset Master unmute 2>/dev/null || true
              ${pkgs.alsa-utils}/bin/amixer -q sset PCM unmute 2>/dev/null || true
              if command -v ${pkgs.pipewire}/bin/wpctl >/dev/null 2>&1; then
                ${pkgs.pipewire}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 2>/dev/null || true
                ${pkgs.pipewire}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.65 2>/dev/null || true
              fi

              # Always run UI in kiosk mode (forces music/audio defaults inside the UI)
              URL="file://${chernosUI}/index.html?kiosk=1"
              if [ "x''${CHERNOS_PERSIST:-0}" = "x1" ]; then
                URL="$URL&persist=1"
              fi

              # Chromium base flags (build argument vector safely)
              set -- \
                --enable-features=UseOzonePlatform \
                --ozone-platform=wayland \
                --kiosk "$URL" \
                --start-fullscreen \
                --noerrdialogs \
                --disable-translate \
                --overscroll-history-navigation=0 \
                --no-first-run \
                --no-default-browser-check \
                --disable-infobars \
                --disable-session-crashed-bubble \
                --autoplay-policy=no-user-gesture-required

              # Persistence-aware profile behavior
              if [ "x''${CHERNOS_PERSIST:-0}" = "x1" ]; then
                set -- "$@" --user-data-dir=/home/kiosk/.config/chromium
              else
                # Keep the live ISO stateless by default
                set -- "$@" --incognito --user-data-dir=/tmp/chromium-profile
              fi

              # Software-rendering fallback (VMs, weak GPUs). Force with CHERNOS_FORCE_SOFTWARE=1
              if [ "x''${CHERNOS_FORCE_SOFTWARE:-0}" = "x1" ] || [ ! -e /dev/dri/renderD128 ]; then
                set -- "$@" --disable-gpu --disable-gpu-compositing --use-gl=swiftshader --disable-features=VaapiVideoDecodeLinuxGL
              fi

              exec ${pkgs.chromium}/bin/chromium "$@"
            '';
          };

          # ---------- greetd -> sway -> Chromium kiosk ----------
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
            alsa-utils
            pipewire
            wireplumber

            # --- installer stack ---
            calamares
            calamares-nixos-extensions
            sudo
            networkmanager

            # partition + fs utilities Calamares relies on
            parted
            gptfdisk
            e2fsprogs
            btrfs-progs
            dosfstools
            ntfs3g
            lvm2
            cryptsetup

            # Qt Wayland plugin (Calamares is Qt6 in current nixpkgs)
            qt6.qtwayland

            # Helps avoid Kirigami/QML warnings (branding uses Kirigami in some configs)
            kdePackages.kirigami
          ];

          # Calamares on NixOS expects distro configuration in /etc/calamares.
          # The NixOS-specific Calamares config ships in calamares-nixos-extensions.
          environment.etc."calamares".source = "${pkgs.calamares-nixos-extensions}/etc/calamares";

          # ---------- /etc/chernos-installer.sh (Calamares launcher) ----------
          environment.etc."chernos-installer.sh" = {
            mode = "0755";
            text = ''
              #!/bin/sh
              set -eu

              # If networking is enabled, make sure it's actually turned on.
              if command -v nmcli >/dev/null 2>&1; then
                nmcli networking on 2>/dev/null || true
              fi

              # Run Calamares as root, but keep Wayland/DBus env so the GUI can connect.
              exec sudo --preserve-env=WAYLAND_DISPLAY,XDG_RUNTIME_DIR,DISPLAY,DBUS_SESSION_BUS_ADDRESS,XAUTHORITY \
                ${pkgs.calamares}/bin/calamares
            '';
          };

          # ---------- sway config: call kiosk script ----------
          environment.etc."sway/config".text = ''
            set $mod Mod4

            # Prevent exit
            bindsym $mod+Shift+e exec echo "exit blocked"

            # Open Calamares installer
            bindsym $mod+i exec /etc/chernos-installer.sh
            bindsym Ctrl+Alt+i exec /etc/chernos-installer.sh

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
