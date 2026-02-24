{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../common/configuration.nix
  ];

  networking.hostName = "desktop";

  boot.kernelPackages = pkgs.linuxPackages_zen;

  # AMD GPU
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Gaming
  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
    remotePlay.openFirewall = true;
    extraCompatPackages = with pkgs; [ proton-ge-bin ];
  };

  programs.gamemode.enable = true;
  programs.gamescope.enable = true;
  programs.corectrl.enable = true;

  environment.systemPackages = with pkgs; [
    mangohud
    protonup-qt
    lutris
    wine
    winetricks
  ];

  # Desktop keyboard layout (us, bg)
  home-manager.users.milen.xdg.configFile."hypr/input.conf".source =
    config.home-manager.users.milen.lib.file.mkOutOfStoreSymlink
      "/home/milen/nixos/config/hypr/input-desktop.conf";
}
