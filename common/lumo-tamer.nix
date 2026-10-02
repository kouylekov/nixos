# lumo-tamer: unofficial proxy that exposes Proton Lumo as an OpenAI-compatible
# API. Not in nixpkgs, so we build it from source.
#
# The Go helper (proton-auth) is built separately because the upstream npm
# `build:login` step assumes network access to the Go module proxy.
{
  lib,
  fetchFromGitHub,
  buildNpmPackage,
  buildGoModule,
  nodejs_22,
  go_1_26,
  python3,
}:

let
  version = "0.6.0";
  rev = "0ef587b7f3d5d5165914602f0cc79bdfe7ee4e30";
  src = fetchFromGitHub {
    owner = "ZeroTricks";
    repo = "lumo-tamer";
    inherit rev;
    hash = "sha256-zhUnfmQzQcB3EEV2o9tHYy/Ov23FesJmYJByOTA7H30=";
  };

  proton-auth = buildGoModule {
    pname = "proton-auth";
    inherit version src;
    sourceRoot = "source/src/auth/login/go";
    go = go_1_26;
    vendorHash = "sha256-S0b+VQFbIG6UtkZUHyz9+g6nq7c9/YTKUzkX+d8i2Ko=";
    ldflags = [ "-s" "-w" ];
    env.CGO_ENABLED = "0";
  };
in
buildNpmPackage {
  pname = "lumo-tamer";
  inherit version src;

  nodejs = nodejs_22;
  # Workspace layout (packages/*) needs fetcher version 2 for packument caching.
  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-GMplGK+9LzhXjvxGh9S7f0OLqhZNfYhK4IEAhE+SKaA=";

  nativeBuildInputs = [ python3 ];

  # Only build the TypeScript; proton-auth comes from the buildGoModule above.
  npmBuildScript = "build";

  # Skip lifecycle/rebuild scripts: keytar and playwright would try to download
  # or compile native artifacts. keytar is lazy-loaded and falls back to the
  # vault key file, and the browser auth method is unused.
  npmRebuildFlags = [ "--ignore-scripts" ];
  env.PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";

  postPatch = ''
    # The server resolves writable state (config.yaml, sessions/, logs) relative
    # to the package dir, which is read-only in the Nix store. Honor an
    # environment override for everything except packaged read-only files.
    substituteInPlace src/app/paths.ts \
      --replace-fail "  return join(PROJECT_ROOT, path);" \
        "  const homeOverride = process.env.LUMO_TAMER_HOME;
  if (homeOverride) {
    const normalized = path.startsWith('./') ? path.slice(2) : path;
    if (!normalized.startsWith('dist/') && normalized !== 'config.defaults.yaml') {
      return join(homeOverride, path);
    }
  }
  return join(PROJECT_ROOT, path);"
  '';

  postInstall = ''
    pkg="$out/lib/node_modules/lumo-tamer"
    # dist/ is gitignored so npm pack omits it; install it explicitly.
    cp -r dist "$pkg/"
    cp config.defaults.yaml "$pkg/"
    cp ${proton-auth}/bin/proton-auth "$pkg/dist/proton-auth"
  '';

  meta = {
    description = "Use Proton's private AI assistant (Lumo) anywhere: OpenAI-compatible API and CLI";
    homepage = "https://github.com/ZeroTricks/lumo-tamer";
    license = lib.licenses.gpl3Only;
    mainProgram = "tamer";
  };
}