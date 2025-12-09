{ config, pkgs, lib, ... }:

{
  ########################################
  # Imports
  ########################################

  imports = [
    ../common/base.nix
  ];

  ########################################
  # Networking
  ########################################

  networking.networkmanager.enable = true;

  ########################################
  # Graphical Desktop: XFCE + LightDM
  ########################################

  services.xserver = {
    enable = true;

    # Keyboard layout
    layout = "us";
    xkbVariant = "";

    # Safe drivers for VirtualBox
    videoDrivers = [ "modesetting" "vesa" ];

    displayManager = {
      # Use LightDM (login screen)
      lightdm.enable = true;
      defaultSession = "xfce";

      lightdm.greeters.slick = {
        enable = true;

        # “ChernOS” dark look using existing themes
        themeName = "Adwaita-dark";
        iconThemeName = "Papirus-Dark";

        # NOTE: `background` option is not available in this nixpkgs version,
        # so we do NOT set it here. Background will come from the theme/greeter.
      };
    };

    desktopManager.xfce = {
      enable = true;
    };
  };

  ########################################
  # System packages (apps & tools)
  ########################################

  environment.systemPackages = with pkgs; [
    # Basics
    vim
    neofetch
    git
    wget
    curl
    htop

    # Desktop apps
    firefox
    thunar

    # Theme & icons
    papirus-icon-theme

    # Sound helper for startup sound
    libcanberra-gtk3
  ];

  ########################################
  # Sound & PipeWire
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
  # Locale & Timezone
  ########################################

  time.timeZone = "Europe/Copenhagen";
  i18n.defaultLocale = "en_US.UTF-8";

  ########################################
  # User
  ########################################

  users.users.nixos = {
    isNormalUser = true;
    password = "nixos";
    extraGroups = [ "wheel" "networkmanager" ];
  };

  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = false;

  ########################################
  # Fonts
  ########################################

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-emoji
    noto-fonts-cjk
  ];

  ########################################
  # ChernOS Startup Sound (on login)
  ########################################

  # This creates a desktop autostart entry that plays a login sound
  # when the XFCE session starts.
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

  # Use a literal path instead of pkgs.nixos-artwork.* so build does not depend
  # on a specific wallpaper attribute. You can later drop your own image at
  # /etc/chernos-wallpaper.png if you like.
  environment.etc."xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <channel name="xfce4-desktop" version="1.0">
      <property name="backdrop" type="empty">
        <property name="screen0" type="empty">
          <property name="monitor0" type="empty">
            <property name="image-path" type="string"
                      value="/etc/chernos-wallpaper.png"/>
          </property>
        </property>
      </property>
    </channel>
  '';
}
