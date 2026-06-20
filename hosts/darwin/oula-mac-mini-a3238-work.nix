{config, ...}: {
  networking = {
    hostName = "oula-mac-mini-a3238-work";
    localHostName = "oula-mac-mini-a3238-work";
  };

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";
}
