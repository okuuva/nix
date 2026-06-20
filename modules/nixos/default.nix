{
  config,
  lib,
  ...
}: {
  config = {
    my.user.home = lib.mkDefault "/home/${config.my.user.name}";

    users.users.${config.my.user.name} = {
      isNormalUser = lib.mkDefault true;
      home = lib.mkDefault config.my.user.home;
    };
  };
}
