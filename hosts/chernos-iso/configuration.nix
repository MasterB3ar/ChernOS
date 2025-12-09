{ config, pkgs, lib, ... }:

{
  ########################################
  # Basic ISO system config
  ########################################
  imports = [
    # You can add extra hardware config or profiles here if needed
  ];

  # Name of the machine
  networking.hostName = "chernos-iso";

  # Enable flakes and nix-command
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Time / locale – adjust if you like
  time.timeZone = "Europe/Copenhagen";
  i18n.defaultLocale = "en_US.UTF-8";

  ########################################
  # Users / autologin for kiosk
  ########################################
  users.users.chernos = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    password = "";
  };

  # Auto-login on TTY1, then we can start sway from there
  services.getty.autologinUser = "chernos";

  ########################################
  # Console / basic system packages
  ########################################
  environment.systemPackages = with pkgs; [
    git
    vim
    curl
    wget
    htop
    neovim
    sway
    alacritty
    wayland-utils
    grim slurp
    chromium
  ];

  ########################################
  # Wayland + Sway kiosk base
  ########################################

  # Enable Sway itself (wayland compositor)
  programs.sway.enable = true;

  # Provide a Sway config as /etc/sway/config
  environment.etc."sway/config".text = ''
    ### ChernOS 2.0 – Sway Kiosk Config

    # Use the default config as base if you want:
    # include /etc/sway/config.d/*

    set $mod Mod4

    # Launch terminal (for debugging / development only)
    bindsym $mod+Return exec alacritty

    # Close focused window
    bindsym $mod+Shift+q kill

    # Fullscreen toggle
    bindsym $mod+f fullscreen

    # Disable common escape keybindings for kiosk-like behavior
    bindsym $mod+Shift+e nop
    bindsym $mod+Shift+c nop
    bindsym $mod+Shift+r nop

    # ChernOS UI (Chromium/Electron) autostart – adjust command as needed
    exec_always chromium --kiosk --start-fullscreen --app=https://localhost

    # Background color
    output * bg #020617 solid_color

    # Basic font + gaps
    font pango:monospace 10
    gaps inner 5
  '';

  ########################################
  # Graphical session autostart
  ########################################

  # Start sway automatically when 'chernos' logs in on tty1
  programs.bash.loginShellInit = ''
    if [ "$(tty)" = "/dev/tty1" ] && [ "$USER" = "chernos" ]; then
      exec sway
    fi
  '';

  ########################################
  # Plymouth boot splash (placeholder for now)
  ########################################
  boot.plymouth.enable = true;
  boot.plymouth.theme = "spinner"; # you can later replace with a custom nuclear-glow theme

  ########################################
  # Filesystem + persistence placeholder
  ########################################
  # For the ISO, root is ephemeral; real persistence via overlayfs can be added later
  fileSystems."/" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [ "mode=755" ];
  };

  # Allow unfree if you later want e.g. proprietary drivers
  nixpkgs.config.allowUnfree = true;

  ########################################
  # Services & misc
  ########################################

  # ISO image setup – important for building the actual ISO
  system.stateVersion = "24.05";
}
