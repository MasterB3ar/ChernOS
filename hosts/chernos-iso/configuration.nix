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
    extraGroups = [ "wheel" "audio " "video" "networkmanager" ];
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

  # Sway – only basic wiring; kiosk config is in /etc/chernos-sway.conf
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraPackages = with pkgs; [
      chromium         # Frontend
      foot             # Minimal terminal for debugging
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

  # Disable traditional getty spam on tty1
  services.getty.autologinUser = "";
  services.getty.helpLine = "";

  ########################################
  # Bootloader, Plymouth, “nuclear glow”
  ########################################

  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "nodev";
  boot.loader.timeout = 2;

  # Simple GRUB theme: dark background, green-ish text
  boot.loader.grub.extraConfig = ''
    set menu_color_normal=light-green/black
    set menu_color_highlight=black/light-green
  '';

  # Plymouth splash
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

    set $mod Mod4

    # Reactor env
    setenv MOZ_ENABLE_WAYLAND 1
    setenv QT_QPA_PLATFORM wayland
    setenv XDG_CURRENT_DESKTOP chernos

    # Debug terminal
    bindsym $mod+Return exec foot

    # Exit sway (for debugging only)
    bindsym $mod+Shift+q exec "swaymsg exit"

    # Launch Chromium in kiosk mode on startup
    exec_always ${pkgs.chromium}/bin/chromium \
      --kiosk \
      --noerrdialogs \
      --disable-session-crashed-bubble \
      --incognito \
      file:///etc/chernos-ui/index.html
  '';
}
