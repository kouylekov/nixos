{
  description = "Python development environment for TSD projects";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      overlays = [
        (final: prev: {
          # Skip failing tests in pipx 1.8.0 - waiting for upstream fix
          # Tests fail due to formatting changes in newer packaging library
          pipx = prev.pipx.overridePythonAttrs (old: {
            doCheck = false;
          });
          # pip-api (a pip-audit dependency) resolves the pip version by
          # spawning `sys.executable -m pip --version`. sys.executable is the
          # bare interpreter in the store, which can't import pip (pip lives in
          # its own output). Wrap pip-audit so pip's site-packages is on
          # PYTHONPATH for this subprocess, without leaking PYTHONPATH into the
          # rest of the dev shell.
          pip-audit = let
            real = prev.pip-audit;
            pipSitePackage = "${prev.python313.pkgs.pip}/${prev.python313.sitePackages}";
          in prev.writeShellScriptBin "pip-audit" ''
            export PYTHONPATH="${pipSitePackage}''${PYTHONPATH:+:$PYTHONPATH}"
            exec "${real}/bin/pip-audit" "$@"
          '';
        })
      ];
    };
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
    # Poetry with poetry-dynamic-versioning so `poetry install` can satisfy the
    # project's [tool.poetry.requires-plugins] without writing to the read-only
    # Nix store. The plugin comes from python3Packages (same interpreter poetry
    # is built against) since it isn't in poetry's curated `plugins` set.
    poetryWithPlugins = pkgs.poetry.withPlugins (_ps: [
      pkgs.python3Packages.poetry-dynamic-versioning
    ]);
  in {
    devShells.${system}.default = pkgs.mkShell {
      packages = [
        python
        pkgs.uv
        pkgs.migrate-to-uv
        poetryWithPlugins
        pkgs.pipx
        pkgs.pip-audit
        pg_config
        pkgs.pkg-config
        pkgs.gcc
        pkgs.gnumake
        postgresql
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

        # CPython build deps (needed by mise when compiling Python from source)
        pkgs.bzip2
        pkgs.ncurses
        pkgs.readline
        pkgs.sqlite
        pkgs.xz
        pkgs.tk

        # general build deps
        pkgs.libffi
        pkgs.zlib

        # greenlet / async support (provides libstdc++)
        pkgs.stdenv.cc.cc.lib
      ];

      env.LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
        postgresql.lib  # psycopg2 / libpq
        pkgs.krb5       # kerberos (libgssapi_krb5, libkrb5)
        pkgs.libsodium  # libnacl
        pkgs.file       # python-magic
        pkgs.openssl    # cryptography
        pkgs.bzip2
        pkgs.ncurses
        pkgs.readline
        pkgs.sqlite
        pkgs.xz
        pkgs.tk
        pkgs.zlib
        pkgs.libffi
        pkgs.stdenv.cc.cc.lib  # libstdc++ for greenlet
      ];

      shellHook = ''
        # Don't leak Nix's global PYTHONPATH (python3.13 site-packages, poetry,
        # pipx, urllib3, ...) into independent venvs like pre-commit's isolated
        # python3.14 hook environments. The packaged tools are self-contained
        # wrapped binaries, so setting this leaks mismatched modules and breaks
        # them (e.g. poetry's requests-toolbelt / poetry-core under py3.14).
        unset PYTHONPATH
        # If this is a Poetry project, make the Poetry virtualenv's interpreter
        # the active `python` instead of the bare system one from the Nix store.
        if [ -f pyproject.toml ] && command -v poetry >/dev/null 2>&1 && poetry env info --path >/dev/null 2>&1; then
          # shellcheck disable=SC1090
          source "$(poetry env info --path)/bin/activate"
        fi
        echo "Python dev shell ready — $(python --version), $(poetry --version)"
      '';
    };
  };
}
