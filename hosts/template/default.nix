# hosts/template/default.nix — 新电脑快速接入模板
# 本文件仅导入通用模块与硬件扫描配置；严禁在此处或 modules/ 中存放任何本机特有配置
{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules
    # 本机特有配置（如特定显卡驱动、微码、专有触摸板等）请新建 ./<hostname>.nix 并在此处 import
  ];

  networking.hostName = "template";
  system.stateVersion = "26.05";
}
