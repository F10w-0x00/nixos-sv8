# modules/graphics.nix — 显示与 Intel 核显驱动
# 包含：Intel UHD 620 核显、VA-API 硬件解码、modesetting 驱动与防闪屏策略
{ pkgs, ... }:

{
  # ── 1. Intel UHD 620 核显与硬件视频加速 ───────
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # Gen9+ (Whiskey Lake) VA-API 硬件解码驱动
      libvdpau-va-gl # VDPAU 兼容层
    ];
  };

  # ── 2. X11 显示驱动 ──────────────────────────
  # 使用通用 modesetting 驱动，避免旧版 xf86-video-intel 引起的画面撕裂
  services.xserver.videoDrivers = [ "modesetting" ];

  # ── 3. 多显示器管理 ──────────────────────────
  # 自动检测与适配 HDMI / Type-C 外接显示器插拔
  services.autorandr.enable = true;

  # ── 4. 核显稳定性与防闪屏策略 ────────────────
  # 禁用 Intel 核显 Panel Self Refresh (PSR) 状态，彻底杜绝 eDP 屏幕偶发闪屏
  boot.kernelParams = [ "i915.enable_psr=0" ];
}
