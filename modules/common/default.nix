# See https://github.com/EmergentMind/nix-config/blob/a811eeb47226eee206ffbe13ab413ae9728cae0a/modules/common/default.nix
# Add your reusable common modules to this directory, on their own file (https://wiki.nixos.org/wiki/NixOS_modules).
# These are modules not specific to either nixos, darwin, or home-manger that you would share with others, not your personal configurations.

{ lib, ... }:
{
  imports = lib.custom.scanPaths ./.;
}
