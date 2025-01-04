{
  ...
}: {
  # Platform-specific configuration
  nix-darwin.inputs.nixpkgs.hostPlatform = "aarch64-darwin";

  system.activationScripts.extraActivation.text = ''
    softwareupdate --install-rosetta --agree-to-license
  '';
}
