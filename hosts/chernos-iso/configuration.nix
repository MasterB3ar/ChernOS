{ config, pkgs, lib, modulesPath, ... }:

{
  ########################################
  # Base: minimal installer ISO
  ########################################

  # This exists in nixos-24.05 and gives you:
  #  - bootable ISO
  #  - installer tooling
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  ########################################
  # Graphical Desktop: XFCE + LightDM
  ########################################

  services.xserver = {
    enable = true;

    # Keyboard
    layout = "us";
    xkbVariant = "";

    # Safe drivers for VM
    videoDrivers = [ "modesetting" "vesa" ];

    # Login manager
    displayManager = {
      lightdm.enable = true;
      # No exotic greeter options – only ones that are known to exist.
    };

    # XFCE desktop
    desktopManager.xfce.enable = true;
  };

  ########################################
  # Timezone & Locale
  ########################################

  time.timeZone = "Europe/Copenhagen";
  i18n.defaultLocale = "en_US.UTF-8";

  ########################################
  # Networking
  ########################################

  # Minimal ISO typically sets this, but forcing true is harmless.
  networking.networkmanager.enable = true;

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
  # Audio (PipeWire stack)
  ########################################

  sound.enable = true;
  hardware.pulseaudio.enable = false;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  ########################################
  # ChernOS Startup Sound (on XFCE session start)
  ########################################

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

  # This is just a string path; Nix does not need the file during evaluation.
  # At runtime XFCE will try to load this image. You can later replace it with
  # your own PNG.
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
  # Users & sudo
  ########################################

  # The minimal ISO profile already sets up the "nixos" user with password "nixos"
  # and sudo rights. We do NOT redefine it here to avoid conflicts.
}
