{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    (python3.withPackages (ps: with ps; [
      pip
      setuptools
      virtualenv
      lxml
      pyqt6
      pyqt6-webengine
    ]))
    openconnect
  ];

  shellHook = ''
    # Create virtual environment with system packages
    if [ ! -d .venv ]; then
      echo "Creating virtual environment..."
      python -m venv --system-site-packages .venv
    fi

    # Activate virtual environment
    source .venv/bin/activate

    # Install openconnect-sso if not already installed
    if ! command -v openconnect-sso &> /dev/null; then
      echo "Installing openconnect-sso dependencies..."
      # Install dependencies without lxml (it's from nixpkgs)
      pip install requests structlog pyxdg toml prompt-toolkit colorama pyqt6-qt6 pyqt6-sip attrs
      # Download and install openconnect-sso without building dependencies
      pip install --no-deps openconnect-sso
    fi

    echo "OpenConnect SSO environment ready!"
    echo "Run: openconnect-sso --server vpn.uio.no"
  '';
}
