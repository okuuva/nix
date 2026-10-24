# Homeslab

Spike's puny home lab.

NixOS host configuration for the x86_64 home server, selected by `nixosConfigurations.homeslab`.
It enables ordinary OpenSSH, Tailscale, a POSIX login shell, Nushell for interactive use, and the existing CD-ripping tools.
It inherits the CLI packages and Fish support from `modules/common`.
No Home Manager, home-directory files, ripping automation, abduco, zmx, ARM, k3s, or Forgejo are configured.

## Disk layout

`disk-config.nix` declares the GPT partitions, LVM volumes, filesystems, and mount points through disko.
`flake.lock` pins disko, and its NixOS module generates the mount configuration from the same definition.
The target is the Samsung SSD 750 at `/dev/disk/by-id/wwn-0x5002538d70258fdf`, not whichever disk happens to be `/dev/sda`.

| Installer mount point | Filesystem | Device | Initial size |
| --- | --- | --- | --- |
| `/mnt/boot` | FAT32 EFI system partition | `/dev/disk/by-partlabel/disk-main-ESP` | 1 GiB |
| `/mnt` | ext4 | `/dev/homeslab/root` | 80 GiB |
| `/mnt/home` | ext4 | `/dev/homeslab/home` | 30 GiB |
| `/mnt/srv` | ext4 | `/dev/homeslab/srv` | 70 GiB |

The LVM partition fills the remaining disk, but the fixed logical-volume sizes leave approximately 52 GiB free inside the `homeslab` volume group.
This reserve can extend any of the ext4 logical volumes later, including while mounted.
No swap is configured.
Normal NixOS rebuilds do not run disko's provisioning scripts or resize existing volumes.
Growing a volume later requires an explicit LVM/filesystem resize; update its declared size afterwards to keep future fresh installs consistent.

## Fresh installation

Boot an x86_64 NixOS installer in UEFI mode and work from a checkout of this repository on the installer USB's live filesystem, not on the SSD being erased.
Verify the NAS backups and confirm that the configured WWN identifies the intended 250 GB Samsung SSD:

```bash
lsblk -o NAME,SIZE,MODEL,SERIAL,WWN,MOUNTPOINTS
readlink -f /dev/disk/by-id/wwn-0x5002538d70258fdf
```

Build the provisioning script using this flake's pinned inputs.
This command only builds the script; it does not touch disks:

```bash
nix --extra-experimental-features 'nix-command flakes' build \
  .#nixosConfigurations.homeslab.config.system.build.destroyFormatMount \
  --out-link result-disko
```

**The next command erases the entire configured SSD, including the old Alpine `vg0` and all existing data.**
Run it only from the live installer after verifying the disk and backups.
It asks for confirmation, then partitions, formats, and mounts the new filesystems under `/mnt`:

```bash
sudo ./result-disko/bin/disko-destroy-format-mount
```

Check the mounts and unallocated VG space, then generate a hardware scan without duplicate filesystem declarations:

```bash
findmnt -R /mnt
sudo vgs homeslab
sudo lvs homeslab
sudo nixos-generate-config --no-filesystems --root /mnt
```

Compare `/mnt/etc/nixos/hardware-configuration.nix` with this host's checked-in hardware configuration, particularly storage drivers.
Keep filesystem definitions in `disk-config.nix` rather than adding them back to `hardware-configuration.nix`.
Then install from the repository checkout:

```bash
sudo nixos-install --flake .#homeslab
sudo nixos-enter --root /mnt -c 'passwd spike'
```

Keep `system.stateVersion` at its initial value after installation.

Set the local password before rebooting so console login and password-authenticated sudo work.
No password or SSH key is embedded in this configuration.
SSH password login and root SSH login are disabled.

Restore the required home-directory files before relying on SSH, including `~/.ssh/authorized_keys`.
The account remains `spike`, UID 1000, GID 1000, with home `/home/spike`.
Preserve ownership and restrictive SSH permissions: 0700 on `~/.ssh` and 0600 on private keys and `authorized_keys`.
Do not copy Alpine's passwd, shadow, or group files over NixOS's account database.
NixOS leaves your dotfiles unmanaged.

The login shell is `/bin/sh`, which NixOS supplies as Bash invoked in sh mode.
Point `~/.profile` at `nushell-wrapper` from your dotfiles to launch Nushell only for interactive login sessions.
Update any restored symlink that still names the old `zp-nushell-wrapper` file.
Non-interactive SSH commands, including Git and rsync, stay in sh.
The wrapper no longer starts zp; that belongs to the Mac's Ghostty launcher.
This host configuration does not install zp or manage the wrapper.

Wired networking uses DHCP without depending on Alpine's `eth0` name.
OpenSSH accepts key authentication on TCP port 22, including from the LAN.
Tailscale's UDP port is also open; no Kubernetes or application ports are opened.
After boot, enroll Tailscale manually with `sudo tailscale up`.
Verify the new node is named `homeslab` so its MagicDNS address is `homeslab.tuna-antares.ts.net`.
Update clients using the old `spike.tuna-antares.ts.net` address, or retain a client-side SSH alias.
Verify the new SSH host-key fingerprint at the local console before updating clients' known-host entries.

## Reusing data on a later installation

Do not rerun the destroy/format command above when preserving data.
For a NixOS reinstall on the unchanged layout, this mount-only script activates LVM and mounts existing filesystems without formatting them:

```bash
nix --extra-experimental-features 'nix-command flakes' build \
  .#nixosConfigurations.homeslab.config.system.build.mount \
  --out-link result-mount
sudo ./result-mount/bin/disko-mount
```

For a different OS, use its installer to reuse the home and srv volumes without formatting them.
Keep the `spike` UID/GID at 1000 when reusing home.
Application data belongs under `/srv`, but future Kubernetes storage must be configured to use it explicitly.
Preserving `/srv` alone does not restore Kubernetes volume claims or cluster state.
These volumes share one SSD and still need NAS backups.

## Existing ripping workflow

Fish remains available for the scripts; your profile can launch Nushell for interactive login sessions.
Restore `~/.abcde.conf`, the Fish functions and variables, their dotfile symlink targets, and the NAS SSH configuration and credentials.
The current destination is `spikenology:/volume2/Media/Music/incoming`.

NixOS's hostname is `homeslab`, not Alpine's `spike.fi`.
On the server, set the Fish universal variable `home_server` to `homeslab` before invoking the old wrappers.
Otherwise their hostname check can take the remote-execution branch and attempt to start the removed abduco.
From a local Fish session:

```fish
set -U home_server homeslab
rip-cd --keep
```

Start Fish explicitly when using the old functions.
Do not use the old client-side remote wrapper until its abduco invocation has been removed.
Without a session manager, keep the SSH session connected while ripping.

Alpine reported `/usr/bin/abcde-musicbrainz-tool` as locally modified.
Compare the backed-up helper with the packaged version before relying on metadata lookup.
If the change is still needed, carry it as a Nix package patch rather than restoring a binary into `/usr/bin`.
No unverified patch is included here.

Test disc access, metadata lookup, encoding, ReplayGain, artwork, ejection, and NAS upload before treating ripping as restored.
Use `--keep` for the first test and verify the uploaded files before deleting local copies.
The old wrapper normally deletes its staging files after a successful rsync.

## Private Git remote

Restore the bare repositories to their existing paths under `/home/spike/gits`, owned by `spike:spike`.
Existing SSH remote URLs can keep using those paths; update their host to `homeslab.tuna-antares.ts.net` or preserve the old name as a client-side SSH alias.
Git runs directly through the host's OpenSSH service; it needs neither a Git daemon nor Kubernetes.
Keep the profile's interactive-shell guard so non-interactive SSH commands do not launch Nushell, and test both fetching and pushing after restoring dotfiles.

If Forgejo is added later, keep these host repositories authoritative and give Forgejo separate mirrors for browsing.
Sharing Forgejo-managed repositories directly would also share its hooks and permissions, potentially making host-side pushes depend on Forgejo.
Forgejo's copies, database, and Kubernetes storage should not become prerequisites for accessing the original bare repositories.
