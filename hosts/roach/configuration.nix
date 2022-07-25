{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      (modulesPath + "/profiles/minimal.nix")
    ];


  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    autoOptimiseStore = true;
    gc.automatic = true;
  };

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnsupportedSystem = true;
    };
  };

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };


  networking = {
    hostName = "roach";
    search = [ "i.rk0n.org" ];
    useDHCP = true;

    firewall = {
      enable = true;
      trustedInterfaces = [ "tailscale0" ];
      allowedTCPPorts = [ 22 ];
      allowedUDPPorts = [ config.services.tailscale.port ];
      checkReversePath = "loose"; # For Tailscale compatibility.
    };
  };

  time.timeZone = "America/Los_Angeles";

  security.sudo.wheelNeedsPassword = false;

  users = {
    mutableUsers = false;
    defaultUserShell = pkgs.zsh;
    users.negz = {
      home = "/home/negz";
      shell = pkgs.zsh;
      isNormalUser = true;
      hashedPassword = "";
      extraGroups = [ "wheel" "docker" ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOW8JjnxKQsDA/y88lkCr6/Z0nxp4/veNdZ0f/hB9qHR"
      ];
    };
  };

  system.stateVersion = "21.11";

  services = {
    openssh = {
      enable = true;
      permitRootLogin = "no";
      passwordAuthentication = false;
    };

    tailscale = {
      enable = true;
      package = pkgs.unstable.tailscale;
    };

    plex = {
      enable = true;
      openFirewall = true;
    };
  };

  programs = {
    zsh.enable = true;
    vim.defaultEditor = true;
  };

  virtualisation = {
    docker.enable = true;
  };

  environment = {
    defaultPackages = lib.mkForce [ ];
  };

  systemd = {
    mounts = [
      {
        description = "Media for Plex";
        where = "/media";
        what = "/dev/disk/by-uuid/62DE-3E98";
        type = "exfat";
        options = "nofail,uid=193,gid=193";  # Plex Media Server runs as uid 193 https://github.com/NixOS/nixpkgs/blob/release-22.05/nixos/modules/misc/ids.nix#L228
        wantedBy = [ "multi-user.target" ];
        mountConfig = {
          TimeoutSec = "10s";
        };
      }
    ];
    automounts = [
      {
        description = "Media for Plex";
        where = "/mnt/media";
        wantedBy = [ "multi-user.target" ];
      }
    ];
  };

}
