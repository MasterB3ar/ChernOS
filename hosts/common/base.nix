{ config, pkgs, lib, ... }:

{
  ########################################
  # Common base settings for all ChernOS hosts
  ########################################

  # Hostname (can be overridden by specific hosts if needed)
  networking.hostName = "chernos-iso";

  # Disable SSH by default (ISO does not need it)
  services.openssh.enable = lib.mkDefault false;

  # Required by NixOS – choose the release you target
  system.stateVersion = "24.05";
}
