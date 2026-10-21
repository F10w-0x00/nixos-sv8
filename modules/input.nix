# modules/input.nix — 键盘与触摸板输入配置
# 包含：标准美式键盘映射、松下经典圆盘触摸板驱动与圆周旋转滚动 (くるくるスクロール)
{ pkgs, ... }:

let
  # 触摸板参数：松下圆盘触摸板边缘旋转滚动灵敏度
  circScrollTrigger = "0"; # 0 表示圆盘任意边缘均可触发顺时针/逆时针旋转滚动
  circScrollDelta = "0.2"; # 滚动步进灵敏度
in
{
  # ── 1. 键盘布局 (标准美式 US) ────────────────
  services.xserver.xkb = {
    layout = "us";
    variant = "";
    options = "";
  };

  console.keyMap = "us";

  # ── 2. 松下圆盘触摸板驱动 ────────────────────
  # 禁用通用 libinput，采用 xf86-input-synaptics 驱动以原生支持圆盘边缘滚动
  services.libinput.enable = false;

  services.xserver.synaptics = {
    enable = true;
    tapButtons = true; # 轻触点击
    fingersMap = [
      1
      3
      2
    ]; # 单指左键、双指右键、三指中键
    buttonsMap = [
      1
      3
      2
    ];
    twoFingerScroll = true; # 保留标准双指平移滚动
    palmDetect = true; # 开启掌压防误触
    additionalOptions = ''
      Option "CircularPad" "on"
      Option "CircularScrolling" "on"
      Option "CircScrollTrigger" "${circScrollTrigger}"
      Option "CircScrollDelta" "${circScrollDelta}"
    '';
  };

  environment.systemPackages = with pkgs; [
    xf86-input-synaptics # 提供 synclient 运行时调试工具
    xinput # 提供 xinput 输入设备管理工具
  ];
}
