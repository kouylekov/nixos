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
        })
      ];
    };
    postgresql = pkgs.postgresql;

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
        pkgs.uv
        pkgs.migrate-to-uv
        poetryWithPlugins
        pkgs.pipx
        postgresql.pg_config
        pkgs.pkg-config
        pkgs.gnumake
        postgresql
        # Node.js provides `npx`, used to run the Redocly CLI for API docs
        pkgs.nodejs
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
        # nixpkgs' python setup-hook leaks every python package's site-packages
        # onto PYTHONPATH (poetry, pipx, migrate-to-uv, ...). Those binaries are
        # already wrapped with their own PYTHONPATH, so this only contaminates
        # child processes (e.g. pre-commit's isolated venvs) with a system poetry
        # that is incompatible with their resolved dulwich. Drop it.
        unset PYTHONPATH
      '';
    };
  };
}
