{ pkgs ? import <nixpkgs> {} }:

let
  # Path to the Cisco installer - user needs to download this
  installerPath = "/home/milen/Downloads/cisco-secure-client-linux64-5.1.8.105-core-vpn-webdeploy-k9.sh";

  fhsEnv = pkgs.buildFHSUserEnv {
    name = "cisco-vpn-fhs";

    targetPkgs = pkgs: with pkgs; [
      # Core libraries
      glibc
      gcc-unwrapped
      zlib
      libz

      # GTK and UI libraries
      gtk3
      gtk2
      glib
      cairo
      pango
      gdk-pixbuf
      atk

      # Qt libraries (Cisco client uses Qt for UI)
      qt5.full
      qt5.qtwebengine
      qt5.qtwebkit

      # X11 libraries
      xorg.libX11
      xorg.libXext
      xorg.libXrender
      xorg.libXft
      xorg.libXi
      xorg.libXrandr
      xorg.libXcursor
      xorg.libXinerama

      # Network libraries
      openssl
      nss
      nspr

      # Other dependencies
      dbus
      fontconfig
      freetype
      libxml2
      libxslt
      icu

      # System tools
      kmod
      which
      gnugrep
      gnused
      gawk
      coreutils
      iproute2
      iptables

      # For the installer
      bash
      gzip
      gnutar
      procps
      util-linux
    ];

    multiPkgs = pkgs: with pkgs; [
      # 32-bit compatibility libraries (Cisco client may need these)
      glibc
      zlib
    ];

    # Set up environment for the VPN client
    profile = ''
      export CISCO_DIR=/opt/cisco/secureclient
      export PATH=$CISCO_DIR/bin:$PATH
      export LD_LIBRARY_PATH=$CISCO_DIR/lib:$LD_LIBRARY_PATH
    '';

    runScript = "bash";
  };

  # Installer wrapper script
  installerScript = pkgs.writeScriptBin "cisco-vpn-install" ''
    #!${pkgs.bash}/bin/bash
    set -e

    if [ ! -f "${installerPath}" ]; then
      echo "Error: Cisco installer not found at ${installerPath}"
      echo "Please download the installer and place it there."
      exit 1
    fi

    echo "Launching FHS environment to install Cisco Secure Client..."
    echo "You will need to run the following command as root inside the FHS environment:"
    echo "  sudo bash ${installerPath}"
    echo ""

    ${fhsEnv}/bin/cisco-vpn-fhs
  '';

  # VPN launcher script
  vpnScript = pkgs.writeScriptBin "cisco-vpn" ''
    #!${pkgs.bash}/bin/bash

    # Check if installed
    if [ ! -d "/opt/cisco/secureclient" ]; then
      echo "Cisco Secure Client is not installed."
      echo "Run 'cisco-vpn-install' first to install it."
      exit 1
    fi

    # Launch VPN in FHS environment
    ${fhsEnv}/bin/cisco-vpn-fhs -c "/opt/cisco/secureclient/bin/vpnui"
  '';

  # CLI VPN launcher
  vpnCLIScript = pkgs.writeScriptBin "cisco-vpn-cli" ''
    #!${pkgs.bash}/bin/bash

    # Check if installed
    if [ ! -d "/opt/cisco/secureclient" ]; then
      echo "Cisco Secure Client is not installed."
      echo "Run 'cisco-vpn-install' first to install it."
      exit 1
    fi

    # Launch VPN CLI in FHS environment
    ${fhsEnv}/bin/cisco-vpn-fhs -c "/opt/cisco/secureclient/bin/vpn $*"
  '';

in pkgs.symlinkJoin {
  name = "cisco-vpn-client";
  paths = [ installerScript vpnScript vpnCLIScript ];
}
