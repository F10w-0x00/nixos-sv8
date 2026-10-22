# modules/input.nix — 键盘与通用输入配置
# 包含：标准美式键盘布局与控制台键位映射
{ ... }:

{
  # ── 1. 键盘布局 (标准美式 US) ────────────────
  services.xserver.xkb = {
    layout = "us";
    variant = "";
    options = "";
  };

  console.keyMap = "us";
}
