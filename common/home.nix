{ config, pkgs, ... }:

{
  home.username = "milen";
  home.homeDirectory = "/home/milen";
  home.stateVersion = "25.11";

  # Dotfile management - symlink directly to repo for live editing
  xdg.configFile = let
    link = path: config.lib.file.mkOutOfStoreSymlink "/home/milen/nixos/config/${path}";
  in {
    "alacritty/alacritty.toml".source = link "alacritty/alacritty.toml";
    "fuzzel/fuzzel.ini".source = link "fuzzel/fuzzel.ini";
    "hypr/hyprland.conf".source = link "hypr/hyprland.conf";
    "hypr/hypridle.conf".source = link "hypr/hypridle.conf";
    "hypr/hyprlock.conf".source = link "hypr/hyprlock.conf";
    "mako/config".source = link "mako/config";
    "waybar/config".source = link "waybar/config";
    "waybar/style.css".source = link "waybar/style.css";
  };

  programs.home-manager.enable = true;
}
