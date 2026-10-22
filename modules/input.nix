# modules/input.nix — 键盘与通用输入配置
# 包含：标准美式键盘布局、控制台键位映射与输入设备冲突过滤
{ ... }:

{
  # ── 1. 键盘布局 (标准美式 US) ────────────────
  services.xserver.xkb = {
    layout = "us";
    variant = "";
    options = "";
  };

  console.keyMap = "us";

  # ── 2. X11 输入设备冲突过滤 ──────────────────
  # 屏蔽 2.4G 接收器附带的多媒体通道被 evdev 误判为第二鼠标，消除双指针焦点争抢导致的瞬间停滞
  services.xserver.extraConfig = ''
    Section "InputClass"
      Identifier "YICHIP Consumer Control Ignore Pointer"
      MatchProduct "YICHIP 2.4G Receiver Consumer Control"
      Option "Ignore" "on"
    EndSection
  '';
}
