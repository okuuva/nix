{
  description = "Spiky nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
  };

  outputs = inputs @ {
    self,
    nix-darwin,
    nixpkgs,
    nix-homebrew,
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
        pkgs.carapace
        pkgs.git
        pkgs.go
        pkgs.fish
        pkgs.fzf
        pkgs.lazygit
        pkgs.neovim
        pkgs.nodejs_22
        pkgs.mkalias
        pkgs.rustc
        pkgs.cargo
        pkgs.tree-sitter
        pkgs.starship
        pkgs.sqlite
        pkgs.ripgrep
        pkgs.zoxide
        pkgs.alacritty
        pkgs.signal-desktop

        pkgs.discord
        pkgs.obsidian
        pkgs._1password-cli
        # pkgs._1password-gui
      ];

      homebrew = {
        enable = true;
        brews = [
          "mas"
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

      # Allow using TouchID for sudo
      security.pam.enableSudoTouchIdAuth = true;

      system.defaults = {
        controlcenter.BatteryShowPercentage = true;
        dock = {
          autohide = true;
          mru-spaces = false;
          persistent-apps = [];
        };
        finder.FXPreferredViewStyle = "Nlsv";
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
    darwinConfigurations."spiky" = nix-darwin.lib.darwinSystem {
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
            user = "spike";
          };
        }
      ];
    };
  };
}
