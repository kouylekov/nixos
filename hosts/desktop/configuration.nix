{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../common/configuration.nix
  ];

  networking.hostName = "desktop";

  # linux-zen 7.3.4 panics at boot (NULL deref in bh_worker while xhci_pci
  # probes the onboard USB controller). Vanilla latest until fixed.
  boot.kernelPackages = pkgs.linuxPackages_latest;

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
}
