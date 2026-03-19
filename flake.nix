{
  description = "My nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    fuse-t-cask = {
      url = "github:macos-fuse-t/homebrew-cask";
      flake = false;
    };
    zmx-tap = {
      url = "github:neurosnap/homebrew-tap";
      flake = false;
    };
    zsm-tap = {
      url = "github:mdsakalu/homebrew-tap";
      flake = false;
    };
    rift-tap = {
      url = "github:acsandmann/homebrew-tap";
      flake = false;
    };
    mise.url = "github:jdx/mise?ref=v2026.2.24";
    mise.inputs.nixpkgs.follows = "nixpkgs"; # the default rustc is too old

    # TODO: go back to unstable once pageup/down is fixed _again_
    jjui.url = "github:NixOS/nixpkgs/7b11c30dad895c0e18ffa60c02c64fc0e89b5723";
  };

  outputs = inputs @ {
    self,
    nix-darwin,
    nixpkgs,
    nix-homebrew,
    homebrew-core,
    homebrew-cask,
    fuse-t-cask,
    zmx-tap,
    zsm-tap,
    rift-tap,
    mise,
    jjui,
  }: let
    jjui-pkgs = import jjui {
      system = "aarch64-darwin";
      config.allowUnfree = true;
    };
    configuration = {
      pkgs,
      config,
      ...
    }: {
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages = [
        pkgs.alejandra # nix linter
        pkgs.bat
        pkgs.btop
        pkgs.carapace
        pkgs.curl
        pkgs.delta
        pkgs.diffnav
        pkgs.fd
        pkgs.fish
        pkgs.fzf
        pkgs.gh
        pkgs.ghostscript_headless
        pkgs.git
        pkgs.glow
        pkgs.gnupg
        pkgs.gnutar
        pkgs.imagemagick
        jjui-pkgs.jjui
        pkgs.jujutsu
        pkgs.k9s
        pkgs.kubectx
        pkgs.lazygit
        pkgs.lsd
        pkgs.mermaid-cli
        pkgs.mkalias
        pkgs.neovim
        pkgs.nix-search-cli
        pkgs.nix-your-shell
        pkgs.nixd # nix lsp
        pkgs.nodejs_22
        pkgs.nushell
        pkgs.page
        pkgs.parallel
        pkgs.pngpaste
        pkgs.prettierd
        pkgs.pwgen
        pkgs.qmk
        pkgs.ripgrep
        pkgs.rustup
        pkgs.shellcheck
        pkgs.shellharden
        pkgs.shfmt
        pkgs.sqlite
        pkgs.starship
        pkgs.stern
        pkgs.stylua
        pkgs.tectonic
        pkgs.tldr
        pkgs.tmux
        pkgs.tree-sitter
        pkgs.uv
        pkgs.wget
        pkgs.yq
        pkgs.zellij
        pkgs.zoxide

        # mac only
        pkgs.pam-reattach
        pkgs.pam-watchid
        pkgs.syncthing-macos
        pkgs.reattach-to-user-namespace

        pkgs._1password-cli
        # pkgs._1password-gui
        # pkgs.obsidian  # stopped working because dmg upacking fails:
        # https://discourse.nixos.org/t/help-with-error-only-hfs-file-systems-are-supported-on-ventura/25873/7

        pkgs.lua51Packages.lua
        pkgs.luajitPackages.luarocks

        pkgs.python312
        pkgs.python312Packages.pylatexenc
        pkgs.python312Packages.pynvim

        # work stuff
        pkgs.vscode

        mise.packages.${pkgs.system}.mise
      ];

      environment.variables = {
        EDITOR = "nvim";
      };

      homebrew = {
        enable = true;
        taps = builtins.attrNames config.nix-homebrew.taps;
        brews = [
          "coreutils" # homebrew version doesn't shadow the builtin commands
          "zmx" # zig does not play ball with nix-darwin
          "zsm" # zmx session manager
          "rift" # only available for macos
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
          "chatterino"
          "fuse-t"
          "fuse-t-sshfs"
          "ghostty"
          "google-drive"
          "helium-browser"
          "iina"
          "karabiner-elements"
          "legcord"
          "obsidian"
          "podman-desktop"
          "raycast"
          "signal"
          "tailscale-app" # tailscale recommend using this instead of the appstore version
          "updf"
          "zen"

          "bruno"
          "choosy"
          "discord"
          "docker-desktop"
          "vivaldi"
          "zoom"
        ];
        onActivation.cleanup = "zap";
        onActivation.autoUpdate = true;
        onActivation.upgrade = true;
      };

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

      system.primaryUser = "oula";

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

      networking = {
        hostName = "oula-mbp-a2485-work";
        localHostName = "oula-mbp-a2485-work";
      };

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Enable alternative shell support in nix-darwin.
      programs.fish.enable = true;
      programs.zsh.enable = true;

      users.users.oula = {
        home = "/Users/oula";
        shell = pkgs.fish;
      };

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 5;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";

      # allow unfree packages
      nixpkgs.config.allowUnfree = true;
    };
  in {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#spiky
    darwinConfigurations."oula-mbp-a2485-work" = nix-darwin.lib.darwinSystem {
      modules = [
        configuration
        nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            # Install Homebrew under the default prefix
            enable = true;

            # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
            enableRosetta = true;

            # User owning the Homebrew prefix
            user = "oula";

            # Enable fully-declarative tap management
            # With mutableTaps disabled, taps can no longer be added imperatively with `brew tap`.
            taps = {
              "homebrew/homebrew-core" = homebrew-core;
              "homebrew/homebrew-cask" = homebrew-cask;
              "macos-fuse-t/homebrew-cask" = fuse-t-cask;
              "neurosnap/homebrew-tap" = zmx-tap;
              "mdsakalu/homebrew-tap" = zsm-tap;
              "acsandmann/homebrew-tap" = rift-tap;
            };
            mutableTaps = false;
          };
        }
      ];
    };
  };
}
