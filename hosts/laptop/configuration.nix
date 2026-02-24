{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../common/configuration.nix
  ];

  networking.hostName = "laptop";

  # Hardware graphics (adjust if your laptop has different GPU)
  hardware.graphics.enable = true;

  # Laptop power management
  services.thermald.enable = true;
  services.power-profiles-daemon.enable = true;

  # Eduroam — run `geteduroam` once to configure via UiO's portal
  environment.systemPackages = [ pkgs.geteduroam ];

  # Home WiFi
  networking.networkmanager.ensureProfiles.profiles.milves = {
    connection = {
      id = "MILVES";
      type = "wifi";
    };
    wifi = {
      ssid = "MILVES";
      mode = "infrastructure";
    };
    wifi-security = {
      key-mgmt = "wpa-psk";
      psk = "$MILVES_PSK";
    };
  };

  networking.networkmanager.ensureProfiles.environmentFiles = [
    "/etc/nixos/secrets/wifi.env"
  ];

  # Laptop keyboard layout (no, us, bg)
  home-manager.users.milen.xdg.configFile."hypr/input.conf".source =
    config.home-manager.users.milen.lib.file.mkOutOfStoreSymlink
      "/home/milen/nixos/config/hypr/input-laptop.conf";
}
