# hosts/sv8/default.nix — Panasonic Let's Note CF-SV8 主机入口配置
{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules
    ./sv8.nix
  ];

  networking.hostName = "sv8";
  system.stateVersion = "26.05";
}
