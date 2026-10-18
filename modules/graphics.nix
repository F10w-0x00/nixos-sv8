# modules/graphics.nix — 显示与 Intel 核显驱动
# 作用：Intel UHD 620 核显配置、VAAPI 硬件编解码加速、modesetting 驱动
# 依赖：无
# 目录：1. 核显驱动与视频加速  2. X11 驱动选项
{ pkgs, ... }:

{
  # ── 1. 核显驱动与视频加速 ────────────────────
  # [SV8] 启用 Intel UHD 620 核显硬件加速与 VAAPI 编解码支持
  # 查文档：nixos-option hardware.graphics.extraPackages
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # Gen9+ Whiskey Lake 推荐驱动（可改/备选：intel-vaapi-driver）
      libvdpau-va-gl # VDPAU 兼容层
    ];
  };

  # ── 2. X11 驱动选项 ──────────────────────────
  # 明确使用 Linux 通用 modesetting 驱动，不安装旧版 xf86-video-intel 以防撕裂与不稳定
  services.xserver.videoDrivers = [ "modesetting" ];
}
