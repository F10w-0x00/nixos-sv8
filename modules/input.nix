# modules/input.nix — 输入设备配置
# 作用：美式标准键盘布局 (US)、松下圆盘触摸板 (Synaptics 驱动 + くるくるスクロール)
# 依赖：pkgs.xf86-input-synaptics, pkgs.xorg.xinput
# 目录：1. 键盘布局 (US)  2. 松下圆盘触摸板 (Synaptics 圆形滚动)
{ pkgs, ... }:

let
  # 触摸板参数调整区（Let's Note CF-SV8 圆形触摸板专用）
  # くるくるスクロール (Circular Scrolling)：沿圆盘边缘画圈实现上下滚动
  circScrollTrigger = "0"; # 0 = 任意边缘均可触发沿圆周旋转滚动
  circScrollDelta = "0.25"; # 滚动步进灵敏度（弧度，默认 0.1 偏快，调大至 0.25 更沉稳适中）
in
{
  # ── 1. 键盘布局 (US) ─────────────────────────
  # 用户决定使用标准美式键盘映射（US QWERTY）
  # 可改：options = "ctrl:nocaps" 交换 CapsLock 与 Ctrl
  services.xserver.xkb = {
    layout = "us";
    variant = "";
    options = "";
  };

  # 控制台终端键盘映射
  console.keyMap = "us";

  # ── 2. 松下圆盘触摸板 (Synaptics 圆形滚动) ──────
  # [SV8] 禁用通用 libinput，切换为 xf86-input-synaptics 驱动以原生支持松下标志性圆盘滚动
  services.libinput.enable = false;

  services.xserver.synaptics = {
    enable = true;
    tapButtons = true; # 开启轻触点击
    fingersMap = [
      1
      3
      2
    ]; # 单指=左键(1)，双指=右键(3)，三指=中键(2)
    buttonsMap = [
      1
      3
      2
    ]; # 物理按键/多指映射
    twoFingerScroll = true; # 双指平移滚动保留可用
    palmDetect = true; # 掌压防误触
    additionalOptions = ''
      Option "CircularPad" "on"
      Option "CircularScrolling" "on"
      Option "CircScrollTrigger" "${circScrollTrigger}"
      Option "CircScrollDelta" "${circScrollDelta}"
    '';
  };

  # 提供 synclient 工具用于运行时动态微调触摸板参数
  environment.systemPackages = with pkgs; [
    xf86-input-synaptics # 提供 synclient
    xorg.xinput # 提供 xinput 设备调试工具
  ];
}
