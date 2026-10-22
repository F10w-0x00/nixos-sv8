# hosts/template/hardware-configuration.nix — 硬件扫描配置占位符
# 实际部署新电脑时，请运行 `nixos-generate-config` 覆盖此文件
{ lib, ... }:

{
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  boot.loader.systemd-boot.enable = true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
