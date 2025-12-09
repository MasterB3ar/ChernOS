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

  services.xserver.enable = false; # Wayland-only, no Xorg

  # Use the legacy, supported graphics options for this nixpkgs
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraPackages = with pkgs; [
      chromium         # Frontend
      foot             # Minimal terminal for debugging
    ];

    # Environment for Sway session
    extraSessionCommands = ''
      export MOZ_ENABLE_WAYLAND=1
      export QT_QPA_PLATFORM=wayland
      export XDG_CURRENT_DESKTOP=chernos
    '';

    # Add our kiosk exec on top of default config
    extraConfig = ''
      # ChernOS Sway additions
      bindsym $mod+Shift+q exec foot
      # Launch Chromium in kiosk mode on startup
      exec "${pkgs.chromium}/bin/chromium \
        --kiosk \
        --noerrdialogs \
        --disable-session-crashed-bubble \
        --incognito \
        file:///etc/chernos-ui/index.html"
    '';
  };

  ########################################
  # greetd – autologin to Sway
  ########################################

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.sway}/bin/sway";
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
}
