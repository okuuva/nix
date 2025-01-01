{
  pkgs,
  config,
  ...
}: {
  environment.systemPackages = [
    pkgs.signal-desktop
    pkgs.discord
    pkgs.obsidian
    pkgs._1password-cli
  ];

  homebrew = {
    enable = true;
    brews = [
      "mas"
      "sqlite" # use brew for now so nvim plugin doesn't panick
    ];
    casks = [
      "bettertouchtool"
      "ghostty"
      "firefox"
      "iina"
      "1password" # regular package does not work on Darwin
    ];
    masApps = {
      "E-kirjasto" = 6471490203;
      "Tailscale" = 1475387142;
    };
    onActivation.cleanup = "zap";
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;
  };

  system.activationScripts.applications.text = let
    env = pkgs.buildEnv {
      name = "system-applications";
      paths = config.environment.systemPackages;
      pathsToLink = "/Applications";
    };
  in
    pkgs.lib.mkForce ''
      echo "setting up /Applications..." >&2
      rm -rf /Applications/Nix\ Apps
      mkdir -p /Applications/Nix\ Apps
      find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
      while read -r src; do
        app_name=$(basename "$src")
        echo "copying $src" >&2
        ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
      done
    '';

  system.activationScripts.extraActivation.text = ''
    softwareupdate --install-rosetta --agree-to-license
  '';

  security.pam.enableSudoTouchIdAuth = true;

  system.defaults = {
    controlcenter.BatteryShowPercentage = true;
    dock = {
      autohide = true;
      mru-spaces = false;
      persistent-apps = [];
    };
    finder = {
      AppleShowAllExtensions = true;
      FXPreferredViewStyle = "Nlsv";
      FXRemoveOldTrashItems = true;
      _FXSortFoldersFirst = true;
    };
    loginwindow.GuestEnabled = false;
    NSGlobalDomain = {
      AppleICUForce24HourTime = true;
      AppleInterfaceStyle = "Dark";
      InitialKeyRepeat = 12;
      KeyRepeat = 2;
    };
  };

  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToEscape = true;
  };

  services.tailscale.enable = true;

  nix.settings.experimental-features = "nix-command flakes";

  programs.fish.enable = true;
}
