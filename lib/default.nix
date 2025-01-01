# See https://github.com/EmergentMind/nix-config/blob/a811eeb47226eee206ffbe13ab413ae9728cae0a/lib/default.nix#L6
# FIXME(lib.custom): Add some stuff from hmajid2301/dotfiles/lib/module/default.nix, as simplifies option declaration
{lib, ...}: {
  # use path relative to the root of the project
  relativeToRoot = lib.path.append ../.;
  scanPaths = path:
    builtins.map (f: (path + "/${f}")) (
      builtins.attrNames (
        lib.attrsets.filterAttrs (
          path: _type:
            (_type == "directory") # include directories
            || (
              (path != "default.nix") # ignore default.nix
              && (lib.strings.hasSuffix ".nix" path) # include .nix files
            )
        ) (builtins.readDir path)
      )
    );
}
