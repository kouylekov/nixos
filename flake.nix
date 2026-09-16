{
  description = "NixOS configuration for Milen";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-matterhorn.url = "github:NixOS/nixpkgs/3e2cf88148e732abc1d259286123e06a9d8c964a";
    # opencode 1.18.30 as built by nixpkgs crashes in SystemPrompt.environment
    # ("TypeError: undefined is not an object (evaluating 'a.name')") before any
    # request reaches the provider, so every prompt fails with a misleading
    # "Unexpected server error". Upstream's own 1.18.30 binary is fine, so this
    # is specific to the nixpkgs source build. Pin the last good one, 1.18.29.
    # Drop this once nixpkgs ships a build that works again.
    nixpkgs-opencode.url = "github:NixOS/nixpkgs/d91a239ca0118ff10ee22ba54f48929c38ab8114";
    mumble-fork = {
      url = "git+https://code.t-juice.club/torjus/mumble.git?ref=nix-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-matterhorn, nixpkgs-opencode, mumble-fork, home-manager }:
  let
    system = "x86_64-linux";
    pkgs-matterhorn = import nixpkgs-matterhorn { inherit system; };
    pkgs-opencode = import nixpkgs-opencode { inherit system; };
  in {
    nixosConfigurations.desktop = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit pkgs-matterhorn pkgs-opencode mumble-fork; };
      modules = [
        ./hosts/desktop/configuration.nix
        home-manager.nixosModules.home-manager
      ];
    };

    nixosConfigurations.laptop = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit pkgs-matterhorn pkgs-opencode mumble-fork; };
      modules = [
        ./hosts/laptop/configuration.nix
        home-manager.nixosModules.home-manager
      ];
    };
  };
}
