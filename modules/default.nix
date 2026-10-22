# modules/default.nix — 通用系统模块统一入口
# 汇集所有与硬件机型解耦的通用模块，供任意主机直接 import
{ ... }:

{
  imports = [
    ./base.nix
    ./graphics.nix
    ./input.nix
    ./power.nix
    ./desktop-dwm.nix
    ./fonts-ime.nix
    ./services.nix
    ./appearance.nix
  ];
}
