{ config, pkgs, lib, ... }:
{
  # NixOS wants to enable GRUB by default
  boot.loader.grub.enable = false;
  # Enables the generation of /boot/extlinux/extlinux.conf
  boot.loader.generic-extlinux-compatible.enable = true;

  # !!! Set to specific linux kernel version
  boot.kernelPackages = pkgs.linuxPackages;

  # Disable ZFS on kernel 6
  boot.supportedFilesystems = lib.mkForce [
    "vfat"
    "xfs"
    "cifs"
    "ntfs"
  ];

  # !!! Needed for the virtual console to work on the RPi 3, as the default of 16M doesn't seem to be enough.
  # If X.org behaves weirdly (I only saw the cursor) then try increasing this to 256M.
  # On a Raspberry Pi 4 with 4 GB, you should either disable this parameter or increase to at least 64M if you want the USB ports to work.
  boot.kernelParams = [ "cma=256M" ];

  # File systems configuration for using the installer's partition layout
  fileSystems = {
    # Prior to 19.09, the boot partition was hosted on the smaller first partition
    # Starting with 19.09, the /boot folder is on the main bigger partition.
    # The following is to be used only with older images.
    /*
      "/boot" = {
      device = "/dev/disk/by-label/NIXOS_BOOT";
      fsType = "vfat";
      };
    */
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
    };
  };

  # !!! Adding a swap file is optional, but strongly recommended!
  swapDevices = [{ device = "/swapfile"; size = 1024; }];

  # Settings above are the bare minimum
  # All settings below are customized depending on your needs

  # systemPackages
  environment.systemPackages = with pkgs; [
    curl
    wget
    micro
    git
    btop
    zellij
    yazi
    podman-compose
    docker-compose
  ];

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };

  networking.firewall.enable = false;

  # WiFi
  hardware = {
    enableRedistributableFirmware = true;
    firmware = [ pkgs.wireless-regdb ];
  };
  # Networking
  networking = {
    # useDHCP = true;
    interfaces.wlan0 = {
      useDHCP = false;
      ipv4.addresses = [{
        # I used static IP over WLAN because I want to use it as local DNS resolver
        address = "192.168.10.22";
        prefixLength = 24;
      }];
    };
    interfaces.eth0 = {
      useDHCP = true;
      # I used DHCP because sometimes I disconnect the LAN cable
      #ipv4.addresses = [{
      #  address = "192.168.100.3";
      #  prefixLength = 24;
      #}];
    };

    # Enabling WIFI
    wireless.enable = true;
    wireless.interfaces = [ "wlan0" ];
    # If you want to connect also via WIFI to your router
    wireless.networks."Scio's Network".psk = "extension";
    # You can set default nameservers
    # nameservers = [ "192.168.100.3" "192.168.100.4" "192.168.100.1" ];
    # You can set default gateway
    # defaultGateway = {
    #  address = "192.168.1.1";
    #  interface = "eth0";
    # };
  };

  # put your own configuration here, for example ssh keys:
  users.mutableUsers = true;
  users.groups = {
    admin = {
      gid = 1000;
      name = "admin";
    };
  };
  users.users = {
    admin = {
      uid = 1000;
      home = "/home/admin";
      name = "admin";
      group = "admin";
      shell = pkgs.zsh;
      extraGroups = [ "wheel" "podman" ];
    };
  };

  system.stateVersion = "25.05";
  system.autoUpgrade = {
    enable = true;
    allowReboot = true;
  };

  users.users."root".openssh.authorizedKeys.keys = [
    #id_scw
    ''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOJp9vehhN1YhdKZqEyhAG+5cinPFYLO6QkOJiO6VGHt iuvm-oci''
    #id_sc24
    ''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILcswHuaFSSX4dVBzPhPco6HpUEJhfgXNwc1pN1eYA/j sayantan.chaudhuri@gmail.com''
    #id_sk24
    ''sk-ecdsa-sha2-nistp256@openssh.com AAAAInNrLWVjZHNhLXNoYTItbmlzdHAyNTZAb3BlbnNzaC5jb20AAAAIbmlzdHAyNTYAAABBBDNc/EfxqykPUuQawkd0PF4gdDM/9Abea7S+hdHQbIV2xlZix/IoKiwQnvU5V8LxatCO79SsjzqshWPRkVy9kbYAAAALc3NoOmlkX3NrMjQ= scio.space''
  ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  virtualisation = {
  	containers.enable = true;
    podman = {
      enable = true;
      dockerCompat = true;
      dockerSocket.enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };
    oci-containers = {
      backend = "podman";
      containers = {
        # container-name = {
        #   image = "container-image";
        #   autoStart = true;
        #   ports = [
        #     "127.0.0.1:1234:1234"
        #   ];
        # };
      };
    };
  };
}
