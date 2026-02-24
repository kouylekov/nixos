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

  # Eduroam (UiO)
  networking.networkmanager.ensureProfiles.profiles.eduroam = {
    connection = {
      id = "eduroam";
      type = "wifi";
    };
    wifi = {
      ssid = "eduroam";
      mode = "infrastructure";
    };
    wifi-security = {
      key-mgmt = "wpa-eap";
    };
    "802-1x" = {
      eap = "peap;";
      identity = "milen@uio.no";
      password-flags = "0";
      phase2-auth = "mschapv2";
    };
  };
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
}
