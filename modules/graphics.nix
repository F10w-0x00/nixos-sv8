# modules/graphics.nix — 通用图形栈与多显示器管理
# 包含：通用图形支持与 autorandr 外接显示器自动配置
{ ... }:

{
  # ── 1. 通用图形渲染栈 ────────────────────────
  hardware.graphics.enable = true;

  # ── 2. 多显示器管理 ──────────────────────────
  # 自动检测与适配外接显示器插拔
  services.autorandr.enable = true;
}
