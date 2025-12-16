{ config, pkgs, lib, ... }:

{
  ########################################
  # Identity
  ########################################
  networking.hostName = "chernos";
  system.stateVersion = "24.05";

  ########################################
  # Nix features (avoid “flakes disabled” surprises)
  ########################################
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  ########################################
  # Locale & Timezone
  ########################################
  time.timeZone = "Europe/Copenhagen";
  i18n.defaultLocale = "en_US.UTF-8";

  ########################################
  # Users
  ########################################
  users.users.chernos = {
    isNormalUser = true;
    createHome = true;
    home = "/home/chernos";
    password = "chernos";
    extraGroups = [ "wheel" "audio" "video" "networkmanager" ];
    uid = 1000;
  };

  # Make root usable in the VM console (prevents “root account is locked” confusion)
  users.users.root.initialPassword = "root";

  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = false;

  ########################################
  # Networking
  ########################################
  networking.networkmanager.enable = true;
  networking.wireless.enable = false;

  ########################################
  # Core services GUI apps usually expect
  ########################################
  services.dbus.enable = true;
  security.polkit.enable = true;

  ########################################
  # Fonts (fix “no text / fontconfig errors”)
  ########################################
  fonts.fontconfig.enable = true;
  fonts.packages = with pkgs; [
    dejavu_fonts
    noto-fonts
    noto-fonts-emoji
    liberation_ttf
  ];

  ########################################
  # Wayland/Sway (kiosk)
  ########################################
  services.xserver.enable = false;

  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;

    extraPackages = with pkgs; [
      chromium
      foot
      swaybg
      swayidle
      wl-clipboard
      xdg-utils
    ];
  };

  ########################################
  # greetd – autologin straight into Sway
  ########################################
  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        user = "chernos";
        # Force software fallbacks for VMs and flaky GPU paths
        command = "${pkgs.bash}/bin/bash -lc 'export WLR_RENDERER_ALLOW_SOFTWARE=1; export LIBGL_ALWAYS_SOFTWARE=0; export WLR_NO_HARDWARE_CURSORS=1; exec ${pkgs.sway}/bin/sway -c /etc/chernos-sway.conf'";
      };

      # Optional fallback greeter (not used normally)
      default_session = {
        user = "greeter";
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd '${pkgs.sway}/bin/sway -c /etc/chernos-sway.conf'";
      };
    };
  };

  ########################################
  # Boot visuals (ISO handles bootloader; we keep Plymouth only)
  ########################################
  boot.plymouth = {
    enable = true;
    theme = "bgrt";
  };

  ########################################
  # Audio – PipeWire
  ########################################
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  ########################################
  # Optional persistence mount (Impermanence)
  ########################################
  fileSystems."/persist" = {
    device = "/dev/disk/by-label/CHERNOS_DATA";
    fsType = "ext4";
    neededForBoot = true;
    options = [ "nofail" ];
  };

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/var/lib/chernos"
      "/var/log"
    ];
    users.chernos = {
      directories = [
        ".config"
        ".cache"
        ".local"
      ];
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/chernos 0755 chernos chernos -"
    "d /home/chernos/.config 0755 chernos chernos -"
    "d /home/chernos/.cache 0755 chernos chernos -"
    "d /home/chernos/.local 0755 chernos chernos -"
  ];

  ########################################
  # Packages
  ########################################
  environment.systemPackages = with pkgs; [
    vim
    git
    htop
    foot
    chromium
  ];

  ########################################
  # Ship UI into /etc/chernos-ui
  ########################################
  environment.etc."chernos-ui/index.html".source = ../../ui/index.html;
  environment.etc."chernos-ui/main.js".source = ../../ui/main.js;
  environment.etc."chernos-ui/styles/blackchamber.css".source = ../../ui/styles/blackchamber.css;

  ########################################
  # Sway config (MUST use exec sh -lc for shell)
  ########################################
  environment.etc."chernos-sway.conf".text = ''
    ### ChernOS v2.0.0 — Sway Kiosk

    set $mod Mod4

    # Known-good black background
    output * bg #000000 solid_color
    seat * hide_cursor 5000

    # Debug terminal
    bindsym $mod+Return exec foot
    bindsym $mod+Shift+q exec "swaymsg exit"

    # Relaunch kiosk quickly: Super+R
    bindsym $mod+r exec sh -lc 'pkill -f "chromium.*chernos-ui" || true; sleep 0.2; exec /bin/true'

    # Start Chromium kiosk (wrapped in a shell so mkdir works)
    # Important: keep this as one line
    exec_always sh -lc 'set -e; mkdir -p "$HOME/.config/chernos-chromium" "$HOME/.cache/chernos-chromium"; export MOZ_ENABLE_WAYLAND=1; export QT_QPA_PLATFORM=wayland; export XDG_CURRENT_DESKTOP=chernos; ${pkgs.chromium}/bin/chromium --no-sandbox --disable-breakpad --disable-crash-reporter --disable-gpu --use-gl=swiftshader --enable-features=UseOzonePlatform --ozone-platform=wayland --kiosk --noerrdialogs --disable-session-crashed-bubble --disable-infobars --incognito --user-data-dir="$HOME/.config/chernos-chromium" --disk-cache-dir="$HOME/.cache/chernos-chromium" file:///etc/chernos-ui/index.html'
  '';
}
