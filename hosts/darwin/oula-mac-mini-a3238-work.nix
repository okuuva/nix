{config, ...}: {
  imports = [../../modules/darwin/work.nix];

  networking = {
    hostName = "oula-mac-mini-a3238-work";
    localHostName = "oula-mac-mini-a3238-work";
  };

  my.kanata.enable = false;

  power = {
    restartAfterFreeze = true;
    restartAfterPowerFailure = true;
  };

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";
}
