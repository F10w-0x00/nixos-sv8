# modules/input.nix — 输入设备配置
# 作用：JIS 物理键盘键位布局、触摸板基础驱动骨架
# 依赖：无
# 目录：1. 键盘布局 (JIS)  2. 触摸板基础设置
{ ... }:

{
  # ── 1. 键盘布局 (JIS) ────────────────────────
  # [SV8] 适配松下机身自带的日文 JIS 物理键盘
  # 可改：layout = "us"（若外接纯美式键盘使用）
  services.xserver.xkb = {
    layout = "jp";
    model = "jp106";
    options = ""; # [ALT] 可配置 "ctrl:nocaps" 交换 CapsLock 与 Ctrl
  };

  # 控制台终端控制键盘映射
  console.keyMap = "jp106";

  # ── 2. 触摸板基础设置 ────────────────────────
  # [SV8] 阶段 1 保持 libinput 通用支持；阶段 3 将切换至 xf86-input-synaptics 以启用松下经典圆形滚动
  services.libinput = {
    enable = true;
    touchpad = {
      naturalScrolling = true; # 开启自然滚动（双指同向）
      tapping = true; # 开启轻触点击
    };
  };
}
