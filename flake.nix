{
  description = "My nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    mise.url = "github:jdx/mise?ref=v2025.3.11";
    mise.inputs.nixpkgs.follows = "nixpkgs"; # the default rustc is too old
  };

  outputs = inputs @ {
    self,
    nix-darwin,
    nixpkgs,
    nix-homebrew,
    homebrew-core,
    homebrew-cask,
    mise,
  }: let
    configuration = {
      pkgs,
      config,
      ...
    }: {
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages = [
        pkgs.alejandra # nix linter
        pkgs.btop
        pkgs.carapace
        pkgs.cargo
        pkgs.curl
        pkgs.fd
        pkgs.fish
        pkgs.fzf
        pkgs.ghostscript_headless
        pkgs.git
        pkgs.glow
        pkgs.gnutar
        pkgs.go
        pkgs.imagemagick
        pkgs.lazygit
        pkgs.lsd
        pkgs.mermaid-cli
        pkgs.mkalias
        pkgs.neovim
        pkgs.nix-search-cli
        pkgs.nixd # nix lsp
        pkgs.nodejs_22
        pkgs.nushell
        pkgs.page
        pkgs.pngpaste
        pkgs.prettierd
        pkgs.qmk
        pkgs.ripgrep
        pkgs.rustc
        pkgs.shellcheck
        pkgs.shellharden
        pkgs.shfmt
        pkgs.sqlite
        pkgs.starship
        pkgs.stylua
        pkgs.tectonic
        pkgs.tldr
        pkgs.tmux
        pkgs.tree-sitter
        pkgs.uv
        pkgs.wget
        pkgs.yq
        pkgs.zoxide

        # mac only
        pkgs.pam-reattach
        pkgs.pam-watchid
        pkgs.reattach-to-user-namespace

        pkgs._1password-cli
        # pkgs._1password-gui
        # pkgs.obsidian  # stopped working because dmg upacking fails:
        # https://discourse.nixos.org/t/help-with-error-only-hfs-file-systems-are-supported-on-ventura/25873/7

        pkgs.lua51Packages.lua
        pkgs.luajitPackages.luarocks

        pkgs.python312Packages.pylatexenc
        pkgs.python312Packages.pynvim

        mise.packages.aarch64-darwin.mise
      ];

      environment.variables = {
        EDITOR = "nvim";
      };

      homebrew = {
        enable = true;
        brews = [
          "mas"
          "coreutils" # homebrew version doesn't shadow the builtin commands
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
          "ghostty"
          "google-drive"
          "iina"
          "legcord"
          "obsidian"
          "podman-desktop"
          "raycast"
          "signal"
          "uhk-agent"
          "zen-browser"

          "choosy"
          "cursor"
          "docker"
          "google-chrome" # regular package has trouble integrating with 1password
          "slack" # regular package does not download
          "whatsapp" # regular package does not download
        ];
        masApps = {
          # "E-kirjasto" = 6471490203;
          "Tailscale" = 1475387142;
        };
        onActivation.cleanup = "zap";
        onActivation.autoUpdate = true;
        onActivation.upgrade = true;
      };

      fonts.packages = [
        pkgs.nerd-fonts.jetbrains-mono
      ];

      system.activationScripts.applications.text = let
        env = pkgs.buildEnv {
          name = "system-applications";
          paths = config.environment.systemPackages;
          pathsToLink = "/Applications";
        };
      in
        pkgs.lib.mkForce ''
          # Set up applications.
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

      # Automatically install rosetta
      system.activationScripts.extraActivation.text = ''
        softwareupdate --install-rosetta --agree-to-license
      '';

      security.pam.services.sudo_local = {
        # Allow using TouchID and Apple Watch for sudo
        touchIdAuth = true;
        watchIdAuth = true;
        # Enable them for tmux as well
        reattach = true;
      };

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
            };
            mutableTaps = false;
          };
        }
      ];
    };
  };
}
