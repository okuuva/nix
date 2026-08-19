# Nix config

## macOS Homebrew troubleshooting

Homebrew packages are declared in `modules/darwin/homebrew.nix`, but manual `brew` commands are still appropriate for repairing Homebrew's installed state.
Do not use them to permanently add or remove declaratively managed packages.

### Cleanup refuses to uninstall a required dependency

`brew bundle` cleanup can mistake a dependency for an undeclared package when an installed formula has stale dependency metadata.
Start with the dependent named in the error and inspect its current dependency tree:

```sh
brew deps --tree anylinuxfs
```

Find the dependency that cleanup tried to remove (`json-c` in this example).
Its immediate parent in the tree (`gettext`) is the likely stale formula.
Compare that formula's current dependencies with the runtime dependencies stored in its installed receipt:

```sh
brew info --json=v2 gettext | python3 -c '
import json, sys
formula = json.load(sys.stdin)["formulae"][0]
print("current:", formula["dependencies"])
print("installed:", [dependency["full_name"] for dependency in formula["installed"][-1]["runtime_dependencies"]])
'
```

If `json-c` appears under `current` but not `installed`, reinstall that formula and rebuild:

```sh
brew reinstall gettext
sudo darwin-rebuild switch --flake .
```

Do not use `brew uninstall --ignore-dependencies`, because that removes a dependency which is still required.
There is no need to remove and re-add `anylinuxfs` in the Nix package list.
