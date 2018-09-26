{ ...
}:

{
  imports = [
  ];

  # Provide minimal information so that NixOS believes it has a system to build
  boot.loader.grub.devices = [ "/dev/sda" ];
  fileSystems."/" = {
    device = "/dev/mapper/vg0/lv0";
    fsType = "ext4";
  };
}
