{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  options.my.kanata = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to run Kanata as a launchd daemon.";
    };

    configPath = lib.mkOption {
      type = lib.types.str;
      default = "${config.my.user.home}/gits/dotfiles/kanata/kanata.kbd";
      description = "Path to the Kanata keyboard configuration for this host.";
    };
  };

  config = {
    my.user.home = lib.mkDefault "/Users/${config.system.primaryUser}";

    environment.systemPackages = with pkgs; [
      # mac only
      mkalias
      pam-reattach
      pam-watchid
      pngpaste
      syncthing-macos
      reattach-to-user-namespace
    ];

    fonts.packages = [
      pkgs.nerd-fonts.jetbrains-mono
    ];

    security.pam.services.sudo_local = {
      # Allow using TouchID and Apple Watch for sudo
      touchIdAuth = true;
      watchIdAuth = true;
      # Enable them for tmux as well
      reattach = true;
    };

    system.primaryUser = lib.mkDefault config.my.user.name;

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
        NewWindowTarget = "Home";
        ShowPathbar = true;
        ShowStatusBar = true;
        _FXSortFoldersFirst = true;
      };
      loginwindow.GuestEnabled = false;
      NSGlobalDomain = {
        AppleICUForce24HourTime = true;
        AppleInterfaceStyle = "Dark";
        InitialKeyRepeat = 20;
        KeyRepeat = 2;
      };
    };

    launchd.daemons.kanata = lib.mkIf config.my.kanata.enable {
      serviceConfig = {
        Label = "com.jtroo.kanata";
        ProgramArguments = [
          "/run/current-system/sw/bin/kanata"
          "--cfg"
          config.my.kanata.configPath
        ];
        RunAtLoad = true;
        KeepAlive = true;
        StandardOutPath = "/tmp/kanata.stdout.log";
        StandardErrorPath = "/tmp/kanata.stderr.log";
      };
    };

    users.users.${config.system.primaryUser} = {
      home = lib.mkDefault config.my.user.home;
      shell = lib.mkDefault pkgs.fish;
    };

    # Set Git commit hash for darwin-version.
    system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;

    # Used for backwards compatibility, please read the changelog before changing.
    # $ darwin-rebuild changelog
    system.stateVersion = 5;
  };
}
