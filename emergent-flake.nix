{
  description = "okuuva's Nix-Config, mostly copied from EmergentMind";
  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    inherit (self) outputs;
    inherit (nixpkgs) lib;

    #
    # ========= Host Config Functions =========
    #
    # Handle a given host config based on whether its underlying system is nixos or darwin
    mkHost = host: platform: {
      ${host} = let
        func =
          if platform == "darwin"
          then inputs.nix-darwin.lib.darwinSystem
          else lib.nixosSystem;
        systemFunc = func;
      in
        systemFunc {
          specialArgs = {
            inherit
              inputs
              outputs
              platform
              ;

            # ========== Extend lib with lib.custom ==========
            # NOTE: This approach allows lib.custom to propagate into hm
            # see: https://github.com/nix-community/home-manager/pull/3454
            lib = nixpkgs.lib.extend (self: super: {custom = import ./lib {inherit (nixpkgs) lib;};});
          };
          modules = [
            ./hosts/${platform}/${host}
          ];
        };
    };
    # Invoke mkHost for each host config that is declared for either nixos or darwin
    mkHostConfigs = hosts: platform: lib.foldl (acc: set: acc // set) {} (lib.map (host: mkHost host platform) hosts);
    # Return the hosts declared in the given directory
    readHosts = folder: lib.attrNames (builtins.readDir ./hosts/${folder});
  in {
    #
    # ========= Overlays =========
    #
    # Custom modifications/overrides to upstream packages.
    overlays = import ./overlays {inherit inputs;};

    #
    # ========= Host Configurations =========
    #
    # Building configurations is available through `just rebuild` or `nixos-rebuild --flake .#hostname`
    # Build [and activate] configurations through `darwin-rebuild [--switch] flake .#hostname
    # nixosConfigurations = mkHostConfigs (readHosts "nixos") false;
    darwinConfigurations = mkHostConfigs (readHosts "darwin") "darwin";

    inputs = {
      # Unstable works for both NixOS and Darwin
      pkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

      # NixOS
      pkgs-stable-nixos.url = "github:nixos/nixpkgs/nixos-23.05";
      nixpkgs.follows = "pkgs-unstable";

      # Darwin (and homebrew)
      pkgs-stable-darwin.url = "github:NixOS/nixpkgs/nixpkgs-23.05-darwin";
      nix-darwin = {
        url = "github:lnl7/nix-darwin";
        inputs.nixpkgs.follows = "pkgs-unstable";
      };
      nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    };
  };
}
