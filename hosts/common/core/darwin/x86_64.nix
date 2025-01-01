{
  pkgs,
  config,
  ...
}: {
  # Platform-specific configuration
  nixpkgs.hostPlatform = "x86_64-darwin";
}
