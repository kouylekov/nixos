{
  description = "NixOS configuration for Milen";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-matterhorn.url = "github:NixOS/nixpkgs/3e2cf88148e732abc1d259286123e06a9d8c964a";
    mumble-fork = {
      url = "git+https://code.t-juice.club/torjus/mumble.git?ref=nix-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-matterhorn, mumble-fork, home-manager }:
  let
    system = "x86_64-linux";
    pkgs-matterhorn = import nixpkgs-matterhorn { inherit system; };
  in {
    nixosConfigurations.desktop = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit pkgs-matterhorn mumble-fork; };
      modules = [
        ./hosts/desktop/configuration.nix
        home-manager.nixosModules.home-manager
      ];
    };

    nixosConfigurations.laptop = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit pkgs-matterhorn mumble-fork; };
      modules = [
        ./hosts/laptop/configuration.nix
        home-manager.nixosModules.home-manager
      ];
    };
  };
}
