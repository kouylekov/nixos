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
    "matterhorn/config.ini".source = link "matterhorn/config.ini";
    "matterhorn/notify".source = link "matterhorn/notify";
  };

  # Classic cursor theme
  home.pointerCursor = {
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
    size = 24;
    gtk.enable = true;
  };

  # Dark theme
  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
  };

  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
    text-scaling-factor = 1.25;
  };

  qt = {
    enable = true;
    platformTheme.name = "adwaita";
    style.name = "adwaita-dark";
  };

  programs.bash = {
    enable = true;
    initExtra = ''
      __git_branch() {
        local branch
        branch=$(git symbolic-ref --short HEAD 2>/dev/null) || return
        echo " ($branch)"
      }
      PS1='\[\e[1;32m\]\u@\h\[\e[0m\]:\[\e[1;34m\]\w\[\e[33m\]$(__git_branch)\[\e[0m\]\$ '
      eval "$(/run/current-system/sw/bin/mise activate bash)"
    '';
  };

  programs.home-manager.enable = true;
}
