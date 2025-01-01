{
  pkgs,
  config,
  ...
}: {
  environment.systemPackages = [
    pkgs.alejandra
    pkgs.carapace
    pkgs.cargo
    pkgs.fish
    pkgs.fzf
    pkgs.git
    pkgs.go
    pkgs.lazygit
    pkgs.mkalias
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

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
}
