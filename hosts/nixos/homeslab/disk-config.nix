{
  disko.devices = {
    disk.main = {
      type = "disk";
      # Samsung SSD 750; verify this WWN in the installer before wiping.
      device = "/dev/disk/by-id/wwn-0x5002538d70258fdf";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              extraArgs = ["-n" "EFI"];
              mountpoint = "/boot";
              mountOptions = ["fmask=0077" "dmask=0077"];
            };
          };
          lvm = {
            size = "100%";
            type = "8E00";
            content = {
              type = "lvm_pv";
              vg = "homeslab";
            };
          };
        };
      };
    };

    lvm_vg.homeslab = {
      type = "lvm_vg";
      # Fixed LV sizes leave about 52 GiB free in the VG for later growth.
      lvs = {
        root = {
          size = "80G";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
        home = {
          size = "30G";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/home";
          };
        };
        srv = {
          size = "70G";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/srv";
          };
        };
      };
    };
  };
}
