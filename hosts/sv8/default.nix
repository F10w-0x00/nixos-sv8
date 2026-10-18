# hosts/sv8/default.nix — SV8 主机入口配置
# 作用：聚合所有功能模块、关联硬件生成配置与主机名
# 依赖：hardware-configuration.nix, modules/*
# 目录：1. 模块导入  2. 主机基本标识
{ config, pkgs, ... }:

{
  # ── 1. 模块导入 ──────────────────────────────
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

  # ── 2. 主机基本标识 ──────────────────────────
  # [SV8] 设定主机名为 sv8，对应 flake 目标 #sv8
  networking.hostName = "sv8";

  # 首次安装时的系统版本，用于数据格式向后兼容，切勿随意修改
  system.stateVersion = "26.05";
}
