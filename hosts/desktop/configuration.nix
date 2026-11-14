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

  # UGREEN NAS (DXP4800 Plus) shared folder over SMB/CIFS. The `personal_folder`
  # share maps to the NAS user's home (/home/milen). Credentials live
  # root-readable at ~/.config/ugreen/ugreen.cred (mode 600, pulled from
  # KeePassXC "Local Admin/UGREEN NAS") and never enter the repo. automount +
  # nofail so the desktop still boots if the NAS is unreachable.
  fileSystems."/mnt/ugreen" = {
    device = "//192.168.50.139/personal_folder";
    fsType = "cifs";
    options = [
      "credentials=/home/milen/.config/ugreen/ugreen.cred"
      "uid=1000"
      "gid=100"
      "file_mode=0660"
      "dir_mode=0770"
      "iocharset=utf8"
      "nofail"
      "_netdev"
      "x-systemd.automount"
      "x-systemd.idle-timeout=60"
    ];
  };
}
