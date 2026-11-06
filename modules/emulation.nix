# modules/emulation.nix — 游戏主机模拟器与兼容运行环境
# 自动化集成 Yuzu EA-4176（Switch 模拟器巅峰稳定版）
{ pkgs, ... }:

let
  # 自动化拉取并校验 Yuzu EA-4176 最终巅峰版 AppImage
  yuzuAppImage = pkgs.fetchurl {
    url = "https://huggingface.co/Dere64/ayudandonavat/resolve/9add33f6c54f1c2e056df2a45d424e70036a9664/Linux-Yuzu-EA-4176.AppImage";
    sha256 = "6d44d52fc6ebd8f3b2e4707516cce535034285d4567302251bafd109c7972258";
  };

  # 通过 appimageTools 补齐 FHS 环境缺失的动态库（如 libgpg-error 与 file 检测）
  yuzu-ea = pkgs.appimageTools.wrapType2 {
    pname = "yuzu";
    version = "4176";
    src = yuzuAppImage;
    extraPkgs = pkgs: with pkgs; [
      file
      libgpg-error
    ];
  };
in
{
  environment.systemPackages = with pkgs; [
    appimage-run # NixOS 通用 AppImage 运行器
    yuzu-ea      # 声明式自动集成 Yuzu，开箱即用并注册桌面与命令行快捷方式
  ];
}
