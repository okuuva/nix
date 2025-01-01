{ pkgs, config, ... }: {
  imports = [
    ./global.nix
    ./macos.nix
    ./apple-silicon.nix
    # Additional host-specific configurations
  ];

  # User owning the Homebrew prefix
  nix-homebrew.user = "oula";

  # Set the state version for backward compatibility
  system.stateVersion = 5;
}
