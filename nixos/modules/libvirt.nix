{
  virtualisation.libvirtd.enable = true;
  users.users.joerg.extraGroups = [ "libvirtd" ];
  networking.firewall.checkReversePath = false;
}
