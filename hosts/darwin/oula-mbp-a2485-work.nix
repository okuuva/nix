{config, ...}: {
  imports = [../../modules/darwin/work.nix];

  networking = {
    hostName = "oula-mbp-a2485-work";
    localHostName = "oula-mbp-a2485-work";
  };

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";
}
