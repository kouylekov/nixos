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

  # Podman
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
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

  # Lid close behavior
  services.logind = {
    lidSwitch = "suspend";
    lidSwitchExternalPower = "lock";
    lidSwitchDocked = "ignore";
  };

  # direnv — auto-load .envrc when entering directories
  home-manager.users.milen.programs.direnv = {
    enable = true;
    nix-direnv.enable = true; # faster Nix integration with cached eval
  };

  home-manager.users.milen.xdg.configFile = {
    # Laptop keyboard layout (no, us, bg)
    "hypr/input.conf".source =
      config.home-manager.users.milen.lib.file.mkOutOfStoreSymlink
        "/home/milen/nixos/config/hypr/input-laptop.conf";
    # Laptop monitors (built-in + external)
    "hypr/monitors.conf".source =
      config.home-manager.users.milen.lib.file.mkOutOfStoreSymlink
        "/home/milen/nixos/config/hypr/monitors-laptop.conf";
  };
}
