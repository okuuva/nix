# See https://github.com/EmergentMind/nix-config/blob/a811eeb47226eee206ffbe13ab413ae9728cae0a/hosts/common/core/default.nix
# IMPORTANT: This is used by NixOS and nix-darwin so options must exist in both!
{
  inputs,
  outputs,
  config,
  lib,
  pkgs,
  isDarwin,
  ...
}: let
  platform =
    if isDarwin
    then "darwin"
    else "nixos";
  platformModules = "${platform}Modules";
in {
  imports = lib.flatten [
    (map lib.custom.relativeToRoot [
      "modules/common"
      "modules/${platform}"
      "hosts/common/core/${platform}.nix"
    ])
  ];

  #
  # ========== Core Host Specifications ==========
  #
  hostSpec = {
    username = "oula";
    inherit
      (inputs.nix-secrets)
      networking
      ;
  };

  networking.hostName = config.hostSpec.hostName;

  #
  # ========== Overlays ==========
  #
  nixpkgs = {
    overlays = [
      outputs.overlays.default
    ];
    config = {
      allowUnfree = true;
    };
  };

  #
  # ========== Nix Nix Nix ==========
  #
  nix = {
    settings = {
      # Deduplicate and optimize nix store
      auto-optimise-store = true;
      warn-dirty = false;

      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };

  #
  # ========== Basic Shell Enablement ==========
  #
  # On darwin it's important these are outside home-manager
  programs.zsh = {
    enable = true;
    enableCompletion = true;
  };

  programs.fish = {
    enable = true;
    enableCompletion = true;
  };

  # Common packages accross all hosts
  environment.systemPackages = [
    pkgs.alejandra
    pkgs.carapace
    pkgs.cargo
    pkgs.fish
    pkgs.fzf
    pkgs.git
    pkgs.go
    pkgs.lazygit
    pkgs.neovim
    pkgs.nodejs_22
    pkgs.nushell
    pkgs.ripgrep
    pkgs.rustc
    pkgs.sqlite
    pkgs.starship
    pkgs.tree-sitter
    pkgs.uv
    pkgs.zoxide
  ];

  environment.variables.EDITOR = "nvim";

  fonts.packages = [
    pkgs.nerd-fonts.jetbrains-mono
  ];
}
