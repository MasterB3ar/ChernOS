{ config, pkgs, lib, modulesPath, ... }:

{
  ########################################
  # Base: graphical XFCE live ISO
  ########################################

  # This pulls in the official NixOS graphical XFCE installer ISO profile.
  # It gives you:
  #  - Live ISO support
  #  - LightDM login manager
  #  - XFCE desktop
  #  - Basic installer tooling
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-graphical-xfce.nix"
  ];

  ########################################
  # Timezone & Locale
  ########################################

  time.timeZone = "Europe/Copenhagen";
  i18n.defaultLocale = "en_US.UTF-8";

  ########################################
  # Extra packages (on top of the default ISO)
  ########################################

  environment.systemPackages = with pkgs; [
    # Tools
    vim
    neofetch
    git
    wget
    curl
    htop

    # Desktop apps
    firefox
    thunar

    # Icons / theme helpers
    papirus-icon-theme

    # For login/startup sound
    libcanberra-gtk3
  ];

  ########################################
  # ChernOS Startup Sound (on XFCE session start)
  ########################################

  # Autostart entry: plays a sound when the XFCE session starts.
  # The installer profile already sets up a user/session,
  # so this will run automatically in the live environment.
  environment.etc."xdg/autostart/chernos-login-sound.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Version=1.0
    Name=ChernOS Startup Sound
    Comment=Play ChernOS login sound
    Exec=canberra-gtk-play -i service-login
    OnlyShowIn=XFCE;
    X-GNOME-Autostart-enabled=true
  '';

  ########################################
  # ChernOS Desktop Branding (wallpaper)
  ########################################

  # We hardcode a wallpaper path string. Nix does NOT need this file at
  # evaluation time — it is just a string. The default ISO already ships
  # NixOS wallpapers under /run/current-system/sw/share/backgrounds, so this
  # path should work. If not, you can later replace the PNG with your own.
  environment.etc."xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <channel name="xfce4-desktop" version="1.0">
      <property name="backdrop" type="empty">
        <property name="screen0" type="empty">
          <property name="monitor0" type="empty">
            <property name="image-path" type="string"
                      value="/run/current-system/sw/share/backgrounds/nixos/nix-wallpaper-simple-dark.png"/>
          </property>
        </property>
      </property>
    </channel>
  '';

  ########################################
  # Networking
  ########################################

  # The installer profile already enables NetworkManager,
  # but setting this again to true is safe and non-conflicting.
  networking.networkmanager.enable = true;

  ########################################
  # Audio (PipeWire stack)
  ########################################

  # The installer profile already does sensible audio defaults,
  # but these are safe and match typical modern config.
  sound.enable = true;
  hardware.pulseaudio.enable = false;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  ########################################
  # Users & sudo
  ########################################

  # The installer ISO profile already provides a "nixos" user with password "nixos"
  # and sudo rights. To avoid conflicts, we do NOT redefine the user here.
  # You log in on TTY/LightDM as:
  #   user: nixos
  #   pass: nixos
}
