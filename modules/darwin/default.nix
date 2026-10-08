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
      CustomUserPreferences."com.apple.iCal".NSUserKeyEquivalents = {
        "Go to Today" = "@$u";
        "Next" = "@$]";
        "Previous" = "@$[";
      };
      # Hotkeys captured from macOS; rebuilds replace the whole dictionary.
      # IDs 16, 18, 20, 22, and 24 were disabled in the captured preferences.
      # They are not set here because their actions are undocumented.
      # Parameters are [character code, virtual keycode, modifier bitmask].
      CustomUserPreferences."com.apple.symbolichotkeys".AppleSymbolicHotKeys = {
        "15".enabled = false; # Toggle accessibility zoom
        "17".enabled = false; # Accessibility zoom in
        "19".enabled = false; # Accessibility zoom out
        "21".enabled = false; # Invert display colors
        "23".enabled = false; # Toggle zoom image smoothing
        "25".enabled = false; # Increase display contrast
        "26".enabled = false; # Decrease display contrast
        "28" = {
          enabled = false; # Save full-screen screenshot to a file
          value = {
            parameters = [51 20 1441792]; # Ctrl+Cmd+Shift+3
            type = "standard";
          };
        };
        "29" = {
          enabled = false; # Copy full-screen screenshot to the clipboard
          value = {
            parameters = [51 20 1179648]; # Cmd+Shift+3
            type = "standard";
          };
        };
        "30" = {
          enabled = false; # Save selected-area screenshot to a file
          value = {
            parameters = [52 21 1441792]; # Ctrl+Cmd+Shift+4
            type = "standard";
          };
        };
        "31" = {
          enabled = false; # Copy selected-area screenshot to the clipboard
          value = {
            parameters = [52 21 1179648]; # Cmd+Shift+4
            type = "standard";
          };
        };
        "60" = {
          enabled = false; # Select the previous keyboard input source
          value = {
            parameters = [32 49 262144]; # Ctrl+Space
            type = "standard";
          };
        };
        "61" = {
          enabled = false; # Select the next source in the Input menu
          value = {
            parameters = [32 49 786432]; # Ctrl+Option+Space
            type = "standard";
          };
        };
        "64" = {
          enabled = true; # Show Spotlight search
          value = {
            parameters = [32 49 524288]; # Option+Space
            type = "standard";
          };
        };
        "65" = {
          enabled = false; # Show Finder search window
          value = {
            parameters = [32 49 1572864]; # Cmd+Option+Space
            type = "standard";
          };
        };
        "79".enabled = true; # Move left a Space
        "80".enabled = true; # Move left a Space with slow animation
        "81".enabled = true; # Move right a Space
        "82".enabled = true; # Move right a Space with slow animation
        "164" = {
          enabled = false; # Dictation keyboard shortcut
          value = {
            parameters = [65535 65535 0]; # Unassigned character/keycode, no modifiers
            type = "standard";
          };
        };
        "176" = {
          enabled = false; # Siri keyboard shortcut
          value.type = "SAE1.0";
        };
        "184" = {
          enabled = false; # Show screenshot and screen-recording options
          value = {
            parameters = [53 23 1179648]; # Cmd+Shift+5
            type = "standard";
          };
        };
      };
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
