# hosts/sv8/default.nix — Panasonic Let's Note CF-SV8 主机入口配置
{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/base.nix
    ../../modules/hardware-sv8.nix
    ../../modules/graphics.nix
    ../../modules/input.nix
    ../../modules/power.nix
    ../../modules/desktop-dwm.nix
    ../../modules/fonts-ime.nix
    ../../modules/services.nix
  ];

  networking.hostName = "sv8";
  system.stateVersion = "26.05";
}
