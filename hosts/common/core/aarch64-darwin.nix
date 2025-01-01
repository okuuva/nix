{
  pkgs,
  config,
  ...
}: {
  # Platform-specific configuration
  nixpkgs.hostPlatform = "aarch64-darwin";

  system.activationScripts.extraActivation.text = ''
    softwareupdate --install-rosetta --agree-to-license
  '';
}
