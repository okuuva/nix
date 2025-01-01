{
  pkgs,
  config,
  ...
}: {
  # Set Git commit hash for darwin-version.
  system.configurationRevision = self.rev or self.dirtyRev or null;

  # Platform-specific configuration
  nixpkgs.hostPlatform = "aarch64-darwin";
}
