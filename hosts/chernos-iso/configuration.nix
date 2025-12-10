{ config, pkgs, lib, ... }:

{
  ########################################
  # Basic system identity
  ########################################

  networking.hostName = "chernos";
  system.stateVersion = "24.05";

  ########################################
  # User & autologin target
  ########################################

  users.users.chernos = {
    isNormalUser = true;
    password = "chernos";
    extraGroups = [ "wheel" "audio" "video" "networkmanager" ];
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

  # No Xorg
  services.xserver.enable = false;

  # OpenGL / Mesa
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  # Sway – frontend wiring; kiosk config is in /etc/chernos-sway.conf
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraPackages = with pkgs; [
      firefox         # Frontend (more stable in this environment)
      foot            # Minimal terminal for debugging
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

  # NOTE: do NOT override services.getty here – the ISO modules handle it.

  ########################################
  # Boot – let the ISO module handle bootloader, we only do Plymouth
  ########################################

  boot.plymouth = {
    enable = true;
    theme = "bgrt";  # safe default, you can override with your own later
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
  # Persistence v3 (profiles, states, logs)
  # /persist is optional (label CHERNOS_DATA), used if present
  ########################################

  fileSystems."/persist" = {
    device = "/dev/disk/by-label/CHERNOS_DATA";
    fsType = "ext4";
    options = [ "nofail" ]; # boot even if disk not present
  };

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/var/lib/chernos"                 # reactor state, logs
      "/home/chernos/.config/chernos"    # UI prefs, profiles
    ];
  };

  # Make sure runtime dirs exist (including Firefox profile dir)
  systemd.tmpfiles.rules = [
    "d /var/lib/chernos 0755 chernos chernos -"
    "d /var/lib/chernos/firefox-profile 0755 chernos chernos -"
  ];

  ########################################
  # Fonts (avoid missing-text issues)
  ########################################

  fonts.packages = with pkgs; [
    dejavu_fonts
  ];

  ########################################
  # System packages – keep it minimal
  ########################################

  environment.systemPackages = with pkgs; [
    vim
    git
    htop
    firefox
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
    ### ChernOS Sway kiosk config

    # Use Super (Windows key) as mod
    set $mod Mod4

    # Solid black background so we know Sway is alive
    output * bg #000000 solid_color

    # Hide cursor after 5 seconds of inactivity
    seat * hide_cursor 5000

    # Always start a terminal so there is at least one window
    exec_always foot

    # Debug terminal (Super+Enter)
    bindsym $mod+Return exec foot

    # Exit sway completely (Super+Shift+Q)
    bindsym $mod+Shift+q exec "swaymsg exit"

    # Simple bar so you see time/status (proves Sway is alive)
    bar {
      position bottom
      status_command while true; do date; sleep 1; done
      font monospace 10
    }

    # Launch Firefox in kiosk mode on startup (Wayland)
    exec_always env MOZ_ENABLE_WAYLAND=1 XDG_CURRENT_DESKTOP=chernos \
      firefox --kiosk --no-remote --profile /var/lib/chernos/firefox-profile \
      file:///etc/chernos-ui/index.html
  '';
}
