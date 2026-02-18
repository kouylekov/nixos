{ config, pkgs, ... }:

{
  home.username = "milen";
  home.homeDirectory = "/home/milen";
  home.stateVersion = "25.11";

  # Dotfile management
  xdg.configFile = {
    "alacritty/alacritty.toml".source = ./config/alacritty/alacritty.toml;
    "fuzzel/fuzzel.ini".source = ./config/fuzzel/fuzzel.ini;
    "hypr/hyprland.conf".source = ./config/hypr/hyprland.conf;
    "hypr/hypridle.conf".source = ./config/hypr/hypridle.conf;
    "hypr/hyprlock.conf".source = ./config/hypr/hyprlock.conf;
    "hypr/hyprpaper.conf".source = ./config/hypr/hyprpaper.conf;
    "mako/config".source = ./config/mako/config;
    "waybar/config".source = ./config/waybar/config;
    "waybar/style.css".source = ./config/waybar/style.css;
  };

  programs.home-manager.enable = true;
}
