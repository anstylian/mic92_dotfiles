
{ config, pkgs, lib, ... }:

with lib;
let
  createContainer = {
    name,
    modules ? [],
    extraFiles ? "",
  }:
  let
     root = "/var/lib/machines/${name}";
     defaultConfig = {
       boot.isContainer = true;
       networking.hostName = mkDefault name;
       networking.useDHCP = false;
       systemd.network.enable = true;
       systemd.package = pkgs.mysystemd;

       # TODO: nscd does resolve users at the moment
       # work around by adding nss modules directly to LD_LIBRARY_PATH
       services.nscd.enable = false;
       systemd.globalEnvironment = {
         LD_LIBRARY_PATH = "${pkgs.systemd.out}/lib";
         SYSTEMD_LOG_LEVEL = "debug";
         DBUS_SYSTEM_BUS_ADDRESS = "unix:path=/var/run/dbus/system_bus_socket";
       };
       environment.sessionVariables = {
         LD_LIBRARY_PATH = "${pkgs.systemd.out}/lib";
         SYSTEMD_LOG_LEVEL = "debug";
         DBUS_SYSTEM_BUS_ADDRESS = "unix:path=/var/run/dbus/system_bus_socket";
       };
       environment.systemPackages = [pkgs.gdb];

       users.users.root.initialPassword = "root";
     };

     config = (import <nixpkgs/nixos/lib/eval-config.nix> {
       modules = [ defaultConfig ] ++ modules;
       prefix = [ "containers" name ];
     }).config;

     containerFiles = pkgs.writeScript "container-files" ''
       d "${root}" 0700 - - -
       d "${root}/etc" 0755 - - -
       w "${root}/etc/resolv.conf" 0700 - - - nameserver 8.8.8.8
       d "${root}/var/lib/private" 0700 - - - -
       d "${root}/nix/var/nix/" 0755 - - -
       d "${root}/root" 0700 - - -
       d "${root}/sbin" 0755 - - -
       L+ "${root}/sbin/init" - - - - ${config.system.build.toplevel}/init
       L "/nix/var/nix/profiles/per-container/${name}" - - - - ${root}/nix/var/nix/profiles/
       L "/nix/var/nix/gcroots/per-container/${name}" - - - - ${root}/nix/var/nix/gcroots/
       ${extraFiles}
     '';
  in {
    systemd.nspawn."${name}.nspawn" = {
      filesConfig = {
        Bind = [
          #"/nix/var/nix/profiles/per-container/${name}:/nix/var/nix/profiles"
          #"/nix/var/nix/gcroots/per-container/${name}:/nix/var/nix/gcroots"
          "/home/joerg/git/systemd"
        ];
        BindReadOnly = [
          "/nix/store"
          "/nix/var/nix/db"
          "/nix/var/nix/daemon-socket"
        ];
      };
    };

    # copy systemd-nspawn@ to systemd-nspawn@${name} to allow overrides
    systemd.packages = [
      (pkgs.runCommand "systemd-nspawn-${name}" {} ''
        mkdir -p $out/lib/systemd/system/
        sed -e 's/%i/${name}/g' ${pkgs.mysystemd}/example/systemd/system/systemd-nspawn@.service \
          > $out/lib/systemd/system/systemd-nspawn-${name}.service
      '')
    ];

    systemd.services."systemd-nspawn-${name}".serviceConfig = {
      ExecStartPre = "${config.systemd.package}/bin/systemd-tmpfiles --create ${containerFiles}";
      ExecStart = [""
      ''
        ${pkgs.mysystemd}/bin/systemd-nspawn -U --link-journal=try-guest --keep-unit --machine ${name} --settings=override --network-veth ${config.system.build.toplevel}/init
      ''];
    };
  };
in createContainer {
  name = "foo";
}
