{ config, pkgs, ... }:

{
  imports = [ ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  boot.loader.grub = {
    enable = true;
    version = 2;
    device = "nodev";
    # TODO: point to real ChernOS theme:
    theme = "/boot/grub/themes/chernos";
  };

  # Plymouth nuclear glow splash (stub path)
  boot.plymouth = {
    enable = true;
    theme = "chernos-glow";
    themePackages = [
      (pkgs.callPackage ./plymouth-theme-chernos-glow.nix { })
    ];
  };

  # Fast-ish boot: fewer services
  boot.kernelParams = [
    "quiet"
    "splash"
    "loglevel=3"
  ];

  networking.hostName = "chernos";
  time.timeZone = "UTC";

  i18n.defaultLocale = "en_US.UTF-8";

  console.keyMap = "us";

  services.xserver.enable = false;

  # Wayland + Sway kiosk
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraPackages = with pkgs; [
      swaylock swayidle xwayland
      alacritty
      chromium
      pavucontrol
    ];
  };

  # Autologin on TTY1 and start sway → chromium
  services.getty.autologinUser = "chernos";

  users.users.chernos = {
    isNormalUser = true;
    extraGroups = [ "wheel" "audio" "video" ];
    initialPassword = "chernos";
  };

  # Simple overlayfs-based persistence (for ISO/USB boot)
  boot.persistence."/persist" = {
    enable = true;
    directories = [
      "/var/log"
      "/var/lib"
      "/home"
    ];
  };

  # Wayland session + kiosk sway config
  environment.etc."sway/config".text = ''
    set $mod Mod4

    output * bg /etc/chernos/wallpapers/core-0x01.png fill

    exec_always --no-startup-id systemd-cat -t chernos-ui \
      /usr/bin/chernos-ui-electron || chromium \
      --kiosk \
      --incognito \
      --noerrdialogs \
      --disable-infobars \
      --app=https://localhost:3000

    bindsym $mod+Shift+e exec "swaymsg exit"
  '';

  systemd.user.services."chernos-sway" = {
    description = "ChernOS Wayland session";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.sway}/bin/sway";
      Restart = "always";
    };
  };

  # Audio + software rendering fallback for VMs
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  # Try llvmpipe if no hardware accel
  environment.variables = {
    LIBGL_ALWAYS_SOFTWARE = "1";
    MESA_LOADER_DRIVER_OVERRIDE = "llvmpipe";
  };

  sound.enable = true;
  hardware.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    jack.enable = true;
  };

  # Calamares installer (stubbed, you’d add real config)
  services.calamares = {
    enable = true;
    package = pkgs.calamares-nixos;
  };

  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    chromium
    # your UI build can be packaged as chernos-ui-electron later
  ];

  system.stateVersion = "24.05";
}
