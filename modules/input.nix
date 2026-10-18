# modules/input.nix — 输入设备配置
# 作用：美式标准键盘布局 (US)、触摸板基础驱动骨架
# 依赖：无
# 目录：1. 键盘布局 (US)  2. 触摸板基础设置
{ ... }:

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

  # ── 2. 触摸板基础设置 ────────────────────────
  # [SV8] 当前使用 libinput 通用驱动；阶段 3 将配置 synaptics 驱动以启用松下经典圆形滚动
  services.libinput = {
    enable = true;
    touchpad = {
      naturalScrolling = true; # 开启自然滚动（双指同向）
      tapping = true; # 开启轻触点击
    };
  };
}
