{pkgs, ...}: {
  imports = [./hardware-configuration.nix ./disk-config.nix];

  networking.hostName = "homeslab";
  networking.useDHCP = true;
  time.timeZone = "Europe/Helsinki";

  my.user.name = "spike";
  users.groups.spike.gid = 1000;
  users.users.spike = {
    uid = 1000;
    group = "spike";
    extraGroups = ["wheel" "cdrom"];
    shell = "/bin/sh";
  };

  programs.nushell.enable = true;

  # Keep keys in ~/.ssh/authorized_keys and repositories in ~/gits.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  services.tailscale = {
    enable = true;
    openFirewall = true;
  };

  # Fish, Git, ImageMagick and Nushell are supplied by modules/common.
  environment.systemPackages = with pkgs; [
    abcde
    cddiscid
    cdparanoia
    lame
    eyed3
    rsgain
    rsync
    util-linux # eject
  ];

  system.stateVersion = "26.11";
}
