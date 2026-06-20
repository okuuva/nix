{
  description = "My Nix system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    nix-auth.url = "github:numtide/nix-auth";
    hunk.url = "github:modem-dev/hunk/v0.16.0";
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    fuse-t-cask = {
      url = "github:macos-fuse-t/homebrew-cask";
      flake = false;
    };
    zmx-tap = {
      url = "github:neurosnap/homebrew-tap";
      flake = false;
    };
    rift-tap = {
      url = "github:acsandmann/homebrew-tap";
      flake = false;
    };
    anylinuxfs-tap = {
      url = "github:nohajc/homebrew-anylinuxfs";
      flake = false;
    };
  };

  outputs = inputs @ {
    nix-darwin,
    nixpkgs,
    nix-homebrew,
    ...
  }: let
    inherit (nixpkgs) lib;

    specialArgs = {inherit inputs;};

    darwinHostFiles = builtins.readDir ./hosts/darwin;
    darwinHostNames =
      builtins.map
      (name: lib.removeSuffix ".nix" name)
      (builtins.filter
        (name: darwinHostFiles.${name} == "regular" && lib.hasSuffix ".nix" name)
        (builtins.attrNames darwinHostFiles));

    mkDarwinHost = hostModule:
      nix-darwin.lib.darwinSystem {
        inherit specialArgs;
        modules = [
          ./modules/common
          ./modules/darwin
          nix-homebrew.darwinModules.nix-homebrew
          ./modules/darwin/homebrew.nix
          hostModule
        ];
      };

    mkNixosHost = {
      system,
      modules ? [],
    }:
      nixpkgs.lib.nixosSystem {
        inherit system specialArgs;
        modules =
          [
            ./modules/common
            ./modules/nixos
          ]
          ++ modules;
      };
  in {
    lib = {
      inherit mkDarwinHost mkNixosHost;
    };

    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#<host-file-name>
    darwinConfigurations = lib.genAttrs darwinHostNames (name: mkDarwinHost ./hosts/darwin/${name}.nix);
  };
}
