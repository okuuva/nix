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
    mkHost = host: isDarwin: {
      ${host} = let
        func =
          if isDarwin
          then inputs.nix-darwin.lib.darwinSystem
          else lib.nixosSystem;
        systemFunc = func;
      in
        systemFunc {
          specialArgs = {
            inherit
              inputs
              outputs
              isDarwin
              ;

            # ========== Extend lib with lib.custom ==========
            # NOTE: This approach allows lib.custom to propagate into hm
            # see: https://github.com/nix-community/home-manager/pull/3454
            lib = nixpkgs.lib.extend (self: super: {custom = import ./lib {inherit (nixpkgs) lib;};});
          };
          modules = [
            ./hosts/${
              if isDarwin
              then "darwin"
              else "nixos"
            }/${host}
          ];
        };
    };
    # Invoke mkHost for each host config that is declared for either nixos or darwin
    mkHostConfigs = hosts: isDarwin: lib.foldl (acc: set: acc // set) {} (lib.map (host: mkHost host isDarwin) hosts);
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
    darwinConfigurations = mkHostConfigs (readHosts "darwin") true;

  inputs = {
    #
    # ========= Official Darwin Package Sources =========
    #

    nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-24.11-darwin";
    nix-darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

  };
}
