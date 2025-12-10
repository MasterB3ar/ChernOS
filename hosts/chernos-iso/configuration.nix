{ config, pkgs, lib, modulesPath, ... }:

{
  ########################################
  # Base: ISO image modules
  ########################################

  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
  ];

  ########################################
  # Basic system identity
  ########################################

  networking.hostName = "chernos";
  system.stateVersion = "24.05";

  ########################################
  # Nix settings (inside the ISO)
  ########################################

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  ########################################
  # User & autologin target
  ########################################

  users.users.chernos = {
    isNormalUser = true;
    password = "chernos";
    extraGroups = [ "wheel" "audio" "video" "networkmanager" ];
    home = "/home/chernos";
  };

  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = false;

  ########################################
  # Locale & Timezone
  ########################################

  time.timeZone = "Europe/Copenhagen";
  i18n.defaultLocale = "en_US.UTF-8";

  ########################################
  # Networking
  ########################################

  networking.networkmanager.enable = true;
  networking.wireless.enable = false; # avoid NM/wireless conflict warnings

  ########################################
  # Graphics / Wayland / Sway kiosk
  ########################################

  # No Xorg – Wayland only
  services.xserver.enable = false;

  # OpenGL / Mesa
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  # Sway – main WM; kiosk config goes into /etc/chernos-sway.conf
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraPackages = with pkgs; [
      chromium           # Frontend
      foot               # Minimal terminal for debugging
      jq                 # handy
    ];
  };

  ########################################
  # greetd – autologin to Sway (+ our config)
  ########################################

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        # Use our custom sway config
        command = "${pkgs.sway}/bin/sway -c /etc/chernos-sway.conf";
        user = "chernos";
      };
    };
  };

  # Do not override services.getty – ISO module handles it.

  ########################################
  # Boot – let the ISO module handle bootloader, only add Plymouth
  ########################################

  boot.plymouth = {
    enable = true;
    theme = "bgrt";  # simple, safe
  };

  ########################################
  # Audio stack – PipeWire
  ########################################

  sound.enable = true;
  hardware.pulseaudio.enable = false;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  ########################################
  # System packages – keep it minimal
  ########################################

  environment.systemPackages = with pkgs; [
    vim
    git
    htop
    chromium
    foot
  ];

  ########################################
  # Ship the ChernOS Reactor UI into /etc/chernos-ui
  ########################################

  environment.etc."chernos-ui/index.html".source =
    ../../ui/index.html;

  environment.etc."chernos-ui/main.js".source =
    ../../ui/main.js;

  environment.etc."chernos-ui/styles/blackchamber.css".source =
    ../../ui/styles/blackchamber.css;

  ########################################
  # Custom Sway config for ChernOS kiosk
  ########################################

  environment.etc."chernos-sway.conf".text = ''
    ### ChernOS v2.0.0 – Sway kiosk config

    # Use Super (Windows key) as mod
    set $mod Mod4

    # Solid black background so we know Sway is alive
    output * bg #000000 solid_color

    # Hide cursor after 5 seconds of inactivity
    seat * hide_cursor 5000

    # Always start a terminal so there is at least one window (debug)
    exec_always foot

    # Debug terminal (Super+Enter)
    bindsym $mod+Return exec foot

    # Exit sway completely (Super+Shift+Q)
    bindsym $mod+Shift+q exec "swaymsg exit"

    # Simple bar so you see time/status (proves Sway is alive)
    bar {
      position bottom
      status_command while true; do date +"%Y-%m-%d %H:%M:%S ChernOS v2.0.0"; sleep 1; done
      font monospace 10
    }

    # Launch Chromium in kiosk mode on startup
    # - dedicated profile dir in HOME
    # - Wayland enabled
    # - crashpad/crash reporter disabled
    exec_always sh -c '
      mkdir -p "$HOME/.config/chernos-chromium" &&
      exec env \
        MOZ_ENABLE_WAYLAND=1 \
        QT_QPA_PLATFORM=wayland \
        XDG_CURRENT_DESKTOP=chernos \
        ${pkgs.chromium}/bin/chromium \
          --user-data-dir="$HOME/.config/chernos-chromium" \
          --kiosk \
          --noerrdialogs \
          --disable-session-crashed-bubble \
          --incognito \
          --disable-breakpad \
          --disable-crash-reporter \
          --enable-features=UseOzonePlatform \
          --ozone-platform=wayland \
          file:///etc/chernos-ui/index.html
    '
  '';
}
