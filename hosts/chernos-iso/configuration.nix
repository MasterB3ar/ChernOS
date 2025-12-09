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
    shell = pkgs.bashInteractive;
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

  # Sway – basic setup; kiosk config is in /etc/chernos-sway.conf
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraPackages = with pkgs; [
      chromium         # Frontend
      foot             # Minimal terminal for debugging
    ];
  };

  ########################################
  # TTY autologin + Sway autostart
  ########################################

  services.getty.autologinUser = lib.mkForce "chernos";

  programs.bash.loginShellInit = ''
    # Only auto-start sway on the first TTY, and only if no Wayland/X is running
    if [ "$(tty)" = "/dev/tty1" ] && [ -z "$WAYLAND_DISPLAY" ] && [ -z "$DISPLAY" ]; then
      exec sway -c /etc/chernos-sway.conf
    fi
  '';

  ########################################
  # Boot – let ISO module handle bootloader, we only do Plymouth
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

  # Make sure runtime dirs exist
  systemd.tmpfiles.rules = [
    "d /var/lib/chernos 0755 chernos chernos -"
  ];

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

    # Simple bar so you see time/status
    bar {
      position bottom
      status_command while true; do date; sleep 1; done
      font monospace 10
    }

    # Hotkey: Super+C to start Chromium manually
    bindsym $mod+c exec /run/current-system/sw/bin/chromium \
      --no-sandbox \
      --disable-gpu \
      --incognito \
      file:///etc/chernos-ui/index.html

    # Autostart Chromium at login (same command)
    exec_always /run/current-system/sw/bin/chromium \
      --no-sandbox \
      --disable-gpu \
      --incognito \
      file:///etc/chernos-ui/index.html \
      >/tmp/chernos-chromium.log 2>&1
  '';
}
