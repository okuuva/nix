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

    signingIdentity = lib.mkOption {
      type = lib.types.str;
      default = "Apple Development: oula.kuuva@azsh.fi (WACPWB32RL)";
      description = "Code-signing identity used for the stable Kanata binary.";
    };
  };

  config = {
    my.user.home = lib.mkDefault "/Users/${config.system.primaryUser}";

    environment.systemPackages = with pkgs;
      [
        # mac only
        mkalias
        pam-reattach
        pam-watchid
        pngpaste
        syncthing-macos
        reattach-to-user-namespace
      ]
      ++ lib.optional config.my.kanata.enable (lib.hiPrio (runCommand "kanata-signed" {} ''
        mkdir -p $out/bin; ln -s /usr/local/libexec/kanata $out/bin/kanata
      ''));

    fonts.packages = [
      pkgs.nerd-fonts.jetbrains-mono
      pkgs.nerd-fonts.dejavu-sans-mono
      pkgs.nerd-fonts.fira-code
      pkgs.julia-mono
      pkgs.freefont_ttf
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
          "/usr/local/libexec/kanata"
          "--cfg"
          config.my.kanata.configPath
        ];
        RunAtLoad = true;
        KeepAlive = true;
        StandardOutPath = "/tmp/kanata.stdout.log";
        StandardErrorPath = "/tmp/kanata.stderr.log";
      };
    };

    system.activationScripts = lib.mkIf config.my.kanata.enable {
      preActivation.text = ''
        kanata=/usr/local/libexec/kanata
        kanataPackage=${pkgs.kanata-with-cmd}
        kanataIdentity=${lib.escapeShellArg config.my.kanata.signingIdentity}
        kanataChanged=false

        mkdir -p /usr/local/libexec
        if [[ ! -x "$kanata" ]] \
          || [[ "$(cat "$kanata.package" 2>/dev/null || true)" != "$kanataPackage:$kanataIdentity" ]]; then
          echo "installing and signing Kanata..." >&2
          kanataTmp=$(mktemp /tmp/kanata.XXXXXX)
          install -m 0755 -o ${lib.escapeShellArg config.system.primaryUser} "$kanataPackage/bin/kanata" "$kanataTmp"
          /usr/bin/sudo --user ${lib.escapeShellArg config.system.primaryUser} --set-home -- \
            /usr/bin/codesign --force --sign "$kanataIdentity" --identifier kanata --timestamp=none "$kanataTmp"
          chown root:wheel "$kanataTmp"
          mv -f "$kanataTmp" "$kanata"
          kanataChanged=true
        fi
      '';

      postActivation.text = ''
        if [[ "$kanataChanged" == true ]]; then
          /bin/launchctl kickstart -k system/com.jtroo.kanata
          if [[ ! -e "$kanata.package" ]]; then
            printf >&2 '\nKanata needs one-time macOS permissions:\n  System Settings > Privacy & Security > Input Monitoring\n  System Settings > Privacy & Security > Accessibility\nUse +, press Command-Shift-G, and select %s in both lists.\nThen run: sudo launchctl kickstart -k system/com.jtroo.kanata\n' "$kanata"
          fi
          printf '%s\n' "$kanataPackage:$kanataIdentity" > "$kanata.package"
        fi
      '';
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
