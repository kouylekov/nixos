{
  description = "Python development environment for TSD projects";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
    python = pkgs.python313;
    postgresql = pkgs.postgresql;

    # psycopg2 needs pg_config which nixpkgs no longer ships as a binary
    pg_config = pkgs.writeShellScriptBin "pg_config" ''
      case "$1" in
        --includedir)    echo "${postgresql.dev}/include";;
        --libdir)        echo "${postgresql.lib}/lib";;
        --pkglibdir)     echo "${postgresql}/lib";;
        --bindir)        echo "${postgresql}/bin";;
        --sharedir)      echo "${postgresql}/share";;
        --sysconfdir)    echo "/etc";;
        --pgxs)          echo "${postgresql.dev}/lib/pgxs/src/makefiles/pgxs.mk";;
        --includedir-server) echo "${postgresql.dev}/include/server";;
        --version)       echo "PostgreSQL ${postgresql.version}";;
        --cflags)        echo "-I${postgresql.dev}/include";;
        --ldflags)       echo "-L${postgresql.lib}/lib";;
        --libs)          echo "-lpq";;
        *)               echo "${postgresql.dev}/include";;
      esac
    '';
  in {
    devShells.${system}.default = pkgs.mkShell {
      packages = [
        python
        pkgs.pipx
        pg_config
        pkgs.pkg-config
        pkgs.gcc
        pkgs.gnumake
        pkgs.bash
      ];

      buildInputs = [
        # psycopg2
        postgresql.lib

        # python-ldap
        pkgs.openldap
        pkgs.cyrus_sasl

        # kerberos
        pkgs.krb5

        # libnacl
        pkgs.libsodium

        # python-magic
        pkgs.file

        # bcrypt / general crypto
        pkgs.openssl

        # general build deps
        pkgs.libffi
        pkgs.zlib
      ];

      env.LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
        pkgs.libsodium  # libnacl
        pkgs.file       # python-magic
        pkgs.openssl    # cryptography
      ];

      shellHook = ''
        export PIPX_HOME="$HOME/.local/pipx"
        export PIPX_BIN_DIR="$HOME/.local/bin"
        export PATH="$PIPX_BIN_DIR:$PATH"
        if ! command -v poetry &>/dev/null; then
          echo "Installing Poetry via pipx..."
          pipx install poetry
        fi
        echo "Python dev shell ready — $(python --version), $(poetry --version)"
      '';
    };
  };
}
