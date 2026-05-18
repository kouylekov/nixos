{ config, pkgs, lib, pkgs-matterhorn, ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Provide /bin/bash for scripts with #!/bin/bash shebangs
  system.activationScripts.binbash = lib.stringAfter [ "stdio" ] ''
    ln -sfn ${pkgs.bash}/bin/bash /bin/bash
  '';

  networking.networkmanager.enable = true;
  services.resolved.enable = true;

  time.timeZone = "Europe/Oslo";
  i18n.defaultLocale = "en_US.UTF-8";

  # Display manager
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "sddm-astronaut-theme";
    extraPackages = [ pkgs.sddm-astronaut ];
  };

  # Override dbus-broker forced by UWSM — it can break SDDM activation
  services.dbus.implementation = lib.mkForce "dbus";

  services.gnome.gnome-keyring.enable = true;
  services.gnome.gcr-ssh-agent.enable = false;
  services.printing.enable = true;
  services.udisks2.enable = true;
  # Temporarily disabled due to meson build race condition in nixos-unstable
  # services.flatpak.enable = true;
  services.fwupd.enable = true;

  # Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Audio
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  users.users.milen = {
    isNormalUser = true;
    description = "Milen Kouylekov";
    extraGroups = [ "networkmanager" "wheel" ];
  };

  # Home Manager
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.milen = import ./home.nix;
  };

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    liberation_ttf
    dejavu_fonts
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
    nerd-fonts.jetbrains-mono
    nerd-fonts.adwaita-mono
    nerd-fonts.bitstream-vera-sans-mono
    nerd-fonts.code-new-roman
    nerd-fonts.noto
    nerd-fonts.symbols-only
    nerd-fonts.terminess-ttf
    nerd-fonts.ubuntu
    nerd-fonts.ubuntu-mono
    nerd-fonts.ubuntu-sans
    nerd-fonts.sauce-code-pro
  ];

  programs.dconf.enable = true;
  programs.git.enable = true;

  # SSH agent
  programs.ssh.startAgent = true;

  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

  programs.firefox.enable = true;

  # Podman
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };
  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [
    (final: prev: {
      openldap = prev.openldap.overrideAttrs (_: { doCheck = false; });
    })
  ];

  # Nix settings
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # Enable nix-ld for running dynamically linked executables (e.g., pre-commit hooks)
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    # Add common libraries that dynamically linked executables might need
    stdenv.cc.cc.lib
    zlib
    openssl
  ];

  environment.systemPackages = with pkgs; [
    sddm-astronaut
    waybar
    fuzzel
    opencode
    alacritty
    ghostty
    xdg-desktop-portal-hyprland
    claude-code
    discord
    mumble
    teams-for-linux
    fastfetch
    python3
    go
    gcc

    # Neovim LSP servers
    pyright
    gopls
    golangci-lint-langserver
    golangci-lint

    # Neovim formatters
    stylua
    ruff

    # Neovim telescope dependencies
    ripgrep
    fd

    # Hyprland ecosystem
    hypridle
    hyprlock
    mako
    grim
    slurp
    wl-clipboard
    cliphist
    brightnessctl
    playerctl
    pavucontrol
    networkmanagerapplet
    blueman
    libnotify
    jq
    ranger
    thunar
    thunar-volman  # volume management plugin (auto-mount in Thunar)
    tumbler        # thumbnail service for Thunar
    ffmpegthumbnailer   # video thumbnail support

    # VPN
    sshuttle
    openconnect
    gpclient
    networkmanager-openconnect

    # Network tools
    bind.dnsutils
    rclone

    # Spell checking
    aspell
    aspellDicts.en

    # Dev tools
    gh
    gnupg
    pinentry-gnome3
    vault
    mise
    pre-commit
    openshift
    psmisc
    btop

    # Communication
    pkgs-matterhorn.matterhorn
    zoom-us

    # Torrent
    rtorrent

    # Media
    vlc

    # Remote desktop
    omnissa-horizon-client
  ];

  system.stateVersion = "25.11";
}
