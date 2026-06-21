{
  config,
  lib,
  inputs,
  ...
}: {
  homebrew = {
    enable = true;
    taps = builtins.attrNames config.nix-homebrew.taps;
    brews = [
      "coreutils" # homebrew version doesn't shadow the builtin commands
      # only available for macos
      # zmx
      "anylinuxfs"
      "rift"
      # anylinuxfs deps
      "libunistring"
      "gettext"
      "util-linux"
      # nvim deps
      "sqlite3"
      "zlib"
      # pyenv-build deps
      "openssl"
      "readline"
      "sqlite3"
      "xz"
      "zlib"
      "tcl-tk@8"
      # ruby-build deps
      "openssl@3"
      "readline"
      "libyaml"
      "gmp"
      "autoconf"
    ];
    casks = [
      "1password" # regular package does not work on Darwin
      "beeper"
      "bettertouchtool"
      "captin"
      "chatterino"
      "fuse-t"
      "fuse-t-sshfs"
      "ghostty"
      "google-drive"
      "helium-browser"
      "iina"
      "karabiner-elements"
      "kitty" # need to install the cask to get the quake terminal keyboard shortcut working
      "legcord"
      "obsidian"
      "podman-desktop"
      "raycast"
      "signal"
      "tailscale-app" # tailscale recommend using this instead of the appstore version
      "updf"
      "zen"
    ];
    onActivation.cleanup = "zap";
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;
  };

  nix-homebrew = {
    # Install Homebrew under the default prefix
    enable = true;

    # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
    enableRosetta = true;

    # User owning the Homebrew prefix
    user = lib.mkDefault config.system.primaryUser;

    # Enable fully-declarative tap management
    # With mutableTaps disabled, taps can no longer be added imperatively with `brew tap`.
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
      "macos-fuse-t/homebrew-cask" = inputs.fuse-t-cask;
      "neurosnap/homebrew-tap" = inputs.zmx-tap;
      "acsandmann/homebrew-tap" = inputs.rift-tap;
      "nohajc/homebrew-tap" = inputs.anylinuxfs-tap;
    };
    mutableTaps = false;
  };
}
