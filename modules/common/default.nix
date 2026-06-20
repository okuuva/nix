{
  lib,
  pkgs,
  inputs,
  ...
}: {
  options.my.user = {
    name = lib.mkOption {
      type = lib.types.str;
      default = "oula";
      description = "Primary human user for this host.";
    };

    home = lib.mkOption {
      type = lib.types.str;
      description = "Home directory for the primary human user.";
    };
  };

  config = {
    # List packages installed in system profile. To search by name, run:
    # $ nix-env -qaP | grep wget
    environment.systemPackages = with pkgs; [
      alejandra # nix linter
      bat
      btop
      carapace
      curl
      delta
      diffnav
      fd
      fish
      fzf
      gh
      ghostscript_headless
      git
      glow
      gnupg
      gnutar
      imagemagick
      (jjui.overrideAttrs (old: rec {
        version = "0.10.2";
        src = fetchFromGitHub {
          owner = "idursun";
          repo = "jjui";
          tag = "v${version}";
          hash = "sha256-VTaOd5LSBxo6EhTyjoyAqX+wTEcm88qIgUCcd+TRYY4=";
        };
        vendorHash = "sha256-GDYgZI6X7UwnyKXOJVmqXXtm4ulA10uuX5MeqKVTheA=";
        ldflags = ["-X main.Version=${version}"];
      }))
      jujutsu
      k9s
      kanata-with-cmd
      kubectx
      lazygit
      lsd
      mermaid-cli
      moor
      neovim
      nix-search-cli
      nix-your-shell
      nixd # nix lsp
      nmap
      nodejs_22
      nufmt
      nushell
      page
      parallel
      prettierd
      pwgen
      qmk
      ripgrep
      rustup
      shellcheck
      shellharden
      shfmt
      sqlite
      starship
      stern
      stylua
      tectonic
      television
      tldr
      tmux
      uv
      wget
      zellij
      zoxide

      _1password-cli
      # _1password-gui
      # obsidian  # stopped working because dmg upacking fails:
      # https://discourse.nixos.org/t/help-with-error-only-hfs-file-systems-are-supported-on-ventura/25873/7

      lua51Packages.lua
      luajitPackages.luarocks
      luajitPackages.tree-sitter-cli

      python312
      python312Packages.pylatexenc
      python312Packages.pynvim

      inputs.nix-auth.packages.${stdenv.hostPlatform.system}.default
      inputs.hunk.packages.${stdenv.hostPlatform.system}.default
    ];

    environment.variables = {
      EDITOR = "nvim";
    };

    # Necessary for using flakes on this system.
    nix.settings.experimental-features = "nix-command flakes";

    programs.fish.enable = true;
    programs.zsh.enable = true;

    # allow unfree packages
    nixpkgs.config.allowUnfree = true;
  };
}
