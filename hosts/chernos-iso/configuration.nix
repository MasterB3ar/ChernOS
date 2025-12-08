{ config, pkgs, lib, modulesPath, ... }:

{
  imports = [
    # Graphical live ISO base profile
    (modulesPath + "/installer/cd-dvd/installation-cd-graphical-base.nix")
  ];

  ########################################
  ## Basic system identity
  ########################################
  networking.hostName = "chernos-iso";
  time.timeZone = "UTC";
  i18n.defaultLocale = "en_US.UTF-8";

  console.keyMap = "us";

  # For live media we allow root login on TTY.
  services.openssh.enable = false;

  ########################################
  ## Users – operator kiosk user
  ########################################
  users.users.operator = {
    isNormalUser = true;
    initialPassword = "chernos"; # live-only, change for real installs
    extraGroups = [ "wheel" "audio" "video" "input" "networkmanager" ];
    description = "ChernOS Operator";
  };

  # Autologin to TTY1 as operator
  services.getty.autologinUser = "operator";

  # Simple sudo for live environment
  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = false;

  ########################################
  ## Networking
  ########################################
  networking.networkmanager.enable = true;

  ########################################
  ## Graphics / Wayland / Sway kiosk
  ########################################
  # Wayland stack + Sway
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraPackages = with pkgs; [
      waybar
      alacritty
      grim
      slurp
      wl-clipboard
      # Add anything you want available in the session
    ];

    # Environment for Wayland and software renderer fallback
    extraSessionCommands = ''
      export MOZ_ENABLE_WAYLAND=1
      export XDG_CURRENT_DESKTOP=sway
      export WLR_RENDERER_ALLOW_SOFTWARE=1
    '';

    # Kiosk Sway config – NO tiling UI, just your dashboard
    extraConfig = ''
      ### ChernOS 2.0 – Sway Kiosk

      # Disable default keybindings that could escape kiosk (tune as needed)
      bindsym Mod4+Shift+e nop
      bindsym Mod4+Shift+q nop
      bindsym Mod4+Return nop

      # Background - solid dark
      output * bg #020617 solid_color

      # Launch Chromium in kiosk mode pointing at the UI
      # Adjust the path/URL once your UI build is mounted somewhere:
      # e.g. file:///home/operator/chernos-2.0/ui/dist/index.html
      exec_always chromium --kiosk --incognito \
        --new-window \
        file:///home/operator/chernos-ui/index.html

      # Optional: terminal accessible with a "hidden" shortcut
      bindsym $mod+Return exec alacritty

      # Exit shortcut (for development/install only)
      bindsym $mod+Shift+Esc exec "swaymsg exit"
    '';
  };

  # Basic hardware opengl + software rendering fallback
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  environment.variables.WLR_RENDERER_ALLOW_SOFTWARE = "1";

  ########################################
  ## Desktop / sound / fonts
  ########################################
  # PipeWire audio (for reactive music system later)
  sound.enable = true;
  hardware.pulseaudio.enable = false;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Basic fonts
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-emoji
    liberation_ttf
  ];

  ########################################
  ## Packages for kiosk + debugging
  ########################################
  environment.systemPackages = with pkgs; [
    chromium
    vim
    git
    htop
    neofetch
    # For debugging the kiosk environment
    alacritty
  ];

  ########################################
  ## Boot loader + Plymouth (no custom assets yet)
  ########################################
  # GRUB configuration suitable for ISO / EFI
  boot.loader.grub = {
    enable = true;
    version = 2;
    efiSupport = true;
    efiInstallAsRemovable = true;
    device = "nodev";
    useOSProber = false;

    # You can later add a splash image or custom theme:
    # splashImage = /path/to/chernos-grub.png;
  };

  # Plymouth splash (nuclear glow aesthetics can be custom later)
  boot.plymouth = {
    enable = true;
    theme = "bgrt"; # placeholder – you can package your own theme
  };

  # ISO image tuning
  isoImage = {
    # Name of the ISO file
    isoName = "chernos-2.0-${config.system.nixos.label}.iso";
  };

  ########################################
  ## Persistence v3 (profiles, states, logs)
  ## Using impermanence – adjust device/label to your setup
  ########################################
  # Expect a partition with label CHERNOS_PERSIST mounted at /persist
  # on real installs / live USB with persistence.
  fileSystems."/persist" = {
    device = "/dev/disk/by-label/CHERNOS_PERSIST";
    fsType = "ext4";
    neededForBoot = false; # for ISO/live; set true on installed system
    # If the device doesn't exist (plain ISO), this mount will just fail
    # at boot but system still continues; you can improve this later.
  };

  # Impermanence-based persistence
  environment.persistence."/persist" = {
    # ChernOS profiles, states, logs:
    directories = [
      "/var/log"
      "/var/lib/nixos"
      "/var/lib/chernos"      # for your Electron/Chromium app state/logs
      "/home/operator"        # operator profile, settings, notes, etc.
    ];
  };

  ########################################
  ## Kiosk / hardening tweaks (basic)
  ########################################
  # Remove unnecessary TTYs to speed boot & limit escape vectors
  services.getty.helpLine = lib.mkDefault "";

  # Optionally reduce number of TTYs:
  # services.getty.ttyDefaults = lib.mkDefault { };

  # Lock root password on live media (optional)
  users.users.root.initialHashedPassword = "";

  ########################################
  ## System version
  ########################################
  # Set to the NixOS release you are targeting
  system.stateVersion = "24.11";
}
