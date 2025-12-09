{ config, pkgs, lib, modulesPath, ... }:

{
  ########################################
  # Base ISO profile
  ########################################

  # Use the standard graphical installation ISO base as a foundation.
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-graphical-base.nix"
  ];

  networking.hostName = "chernos-iso";

  ########################################
  # Locale & console
  ########################################

  time.timeZone = "Europe/Copenhagen";

  i18n.defaultLocale = "en_US.UTF-8";

  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  ########################################
  # Disable SSH on ISO (avoids conflict)
  ########################################

  # The installation ISO profile turns SSH on by default.
  # For a kiosk-style environment we hard-disable it.
  services.openssh.enable = lib.mkForce false;

  ########################################
  # Wayland + Sway kiosk base
  ########################################

  # We do NOT use X11 here; force it off to avoid conflicts.
  services.xserver.enable = lib.mkForce false;

  programs.sway = {
    enable = true;
    # Enable some extras so apps look normal under Sway.
    wrapperFeatures.gtk = true;
  };

  ########################################
  # Kiosk operator user + autologin
  ########################################

  users.users.chernos = {
    isNormalUser = true;
    description = "ChernOS Operator";
    initialPassword = "chernos";
    extraGroups = [ "wheel" "networkmanager" ];
  };

  # Simple, supported autologin configuration.
  # This is the only thing we rely on from the getty module.
  services.getty.autologinUser = "chernos";

  # Let wheel sudo without password inside the ISO.
  security.sudo.wheelNeedsPassword = false;

  ########################################
  # Systemd user session – start Sway on login
  ########################################

  # When user 'chernos' logs in on tty1, their user systemd
  # default.target starts, which starts this service -> Sway.
  systemd.user.services."chernos-session" = {
    description = "ChernOS kiosk session";
    wantedBy = [ "default.target" ];

    serviceConfig = {
      ExecStart = "${pkgs.sway}/bin/sway";
      Restart = "on-failure";
    };
  };

  ########################################
  # Packages in the ISO
  ########################################

  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    sway
    wayland
    xwayland
    grim
    slurp
    chromium
    htop
  ];

  ########################################
  # Misc
  ########################################

  # Needed for NixOS to know how to migrate config later.
  system.stateVersion = "24.05";
}
