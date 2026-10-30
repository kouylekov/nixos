{ config, pkgs, lib, pkgs-matterhorn, pkgs-opencode, ... }:

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

  fonts = {
    packages = with pkgs; [
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

    fontconfig = {
      enable = true;
      antialias = true;
      hinting = {
        enable = true;
        style = "slight";  # Options: none, slight, medium, full
      };
      subpixel = {
        rgba = "rgb";  # Options: rgb, bgr, vrgb, vbgr, none
        lcdfilter = "default";  # Options: default, light, legacy, none
      };
    };
  };

  programs.dconf.enable = true;
  programs.git.enable = true;

  # SSH agent
  programs.ssh.startAgent = true;

  # Niri compositor; config lives in config/niri/.
  programs.niri.enable = true;
  services.displayManager.defaultSession = "niri";

  # PAM entry so swaylock can check the password.
  security.pam.services.swaylock = {};

  # Polkit agent: shows the password prompt when a GUI app asks for admin
  # rights. Tied to niri's graphical session so it starts and stops with it.
  security.polkit.enable = true;
  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    description = "polkit-gnome-authentication-agent-1";
    wantedBy = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };

  programs.firefox.enable = true;

  # niri isn't a DE that xdg-open knows, so it takes its "generic" path. If the
  # caller's environment lacks XDG_DATA_DIRS it can't find firefox.desktop and
  # falls back to a hardcoded list starting with Debian's x-www-browser, which
  # doesn't exist here ("x-www-browser: command not found"). Setting BROWSER
  # short-circuits that list; the explicit mime defaults stop the lookup from
  # depending on mimeinfo.cache scanning.
  environment.sessionVariables.BROWSER = "firefox";
  xdg.mime.defaultApplications = {
    "text/html" = "firefox.desktop";
    "x-scheme-handler/http" = "firefox.desktop";
    "x-scheme-handler/https" = "firefox.desktop";
  } // lib.genAttrs [
    # Without these, image/* has no handler at all and xdg-open dumps pictures
    # into a Firefox tab. imv ships imv.desktop covering all of these.
    "image/png"
    "image/jpeg"
    "image/gif"
    "image/webp"
    "image/bmp"
    "image/tiff"
    "image/avif"
    "image/heif"
    "image/jxl"
    "image/svg+xml"
  ] (_: "imv.desktop");

  # Podman
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };
  nixpkgs.config.allowUnfree = true;

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
    # Display manager theme
    sddm-astronaut
    qt5.qtgraphicaleffects

    waybar
    fuzzel
    # Pinned to 1.18.29 — see the nixpkgs-opencode input in flake.nix
    pkgs-opencode.opencode
    alacritty
    # Niri has no built-in XWayland; it spawns this on demand for X11 apps
    # (Steam, Discord, Zoom, Horizon, matterhorn's xclip, ...).
    xwayland-satellite
    claude-code
    discord
    # Mumble's native PipeWire backend spins in its SCHED_RR data-loop thread,
    # blowing the 200ms RLIMIT_RTTIME rtkit grants it, so the kernel SIGKILLs
    # the process a few seconds after startup. Drop it and use PulseAudio
    # (served by pipewire-pulse) instead.
    #
    # We used to pull Mumble from torjus' fork, which adds Wayland global
    # shortcuts (push-to-talk while unfocused) via the xdg-desktop-portal
    # GlobalShortcuts interface. Niri doesn't implement that portal, so the
    # fork buys us nothing here — back to the nixpkgs package.
    (mumble.override { pipewireSupport = false; })


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

    # Wayland tools
    swaybg
    swayidle
    swaylock
    mako
    grim
    slurp
    imv
    wf-recorder
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
    elinks

    # Spell checking
    aspell
    aspellDicts.en
    aspellDicts.nb
    aspellDicts.bg

    # Office suite
        libreoffice-qt-stable
    hunspell
    hunspellDicts.en_US
    hunspellDicts.nb_NO

    # Dev tools
    gh
    gnupg
    pinentry-gnome3
    vault
    mise
    pre-commit
    openshift
    psmisc
    unzip
    btop

    # Communication
    pkgs-matterhorn.matterhorn
    xclip  # matterhorn yanks via Hclip, which only knows xclip/xsel (bridged to
           # the Wayland clipboard by xwayland-satellite)
    zoom-us

    # Torrent
    rtorrent

    # Media
    vlc

    # Remote desktop
    omnissa-horizon-client

    # Password manager
    keepassxc
    pass
  ];

  system.stateVersion = "25.11";
}
