# modules/graphics.nix — 显示与 Intel 核显驱动
# 作用：Intel UHD 620 核显配置、VAAPI 硬件编解码加速、modesetting 驱动、外接显示器管理
# 依赖：pkgs.intel-media-driver, pkgs.libvdpau-va-gl
# 目录：1. 核显驱动与视频加速  2. X11 驱动选项  3. 多显示器管理 (autorandr)
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

  # ── 3. 多显示器管理 (autorandr) ───────────────
  # [SV8] 自动处理 HDMI / Type-C 外接显示器插拔事件，与 Fn+F8 屏幕切换联动
  # 查文档：man autorandr
  services.autorandr.enable = true;

  # ── 4. 闪屏抑制与核显稳定性参数 ──────────────────
  # [SV8] 针对 Intel UHD 620 在 eDP 屏幕上因 Panel Self Refresh (PSR) 造成的偶发瞬间闪烁/黑屏
  # 严格按任务书排查序列第 1 步：关闭 i915 PSR 节能状态，保持显示链路时钟同步绝对稳定
  # [TEST] 若仍偶发闪屏，下一阶段候选：i915.enable_fbc=0
  # 查文档：man boot.kernelParams / modinfo i915
  boot.kernelParams = [ "i915.enable_psr=0" ];
}

