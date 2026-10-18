# modules/desktop-dwm.nix — 桌面环境与窗口管理器
# 作用：桌面环境配置（阶段 1 保持现有桌面基线；阶段 2 迁入 DWM）
# 依赖：无
# 目录：1. X11 与显示服务  2. 桌面环境基线
{ pkgs, ... }:

{
  # ── 1. X11 与显示服务 ────────────────────────
  services.xserver.enable = true;

  # ── 2. 桌面环境基线 ──────────────────────────
  # [TEST 阶段 1 基线] 暂时保留现有 Plasma 6 / SDDM，确保基线迁移平滑且完全等价
  # 阶段 2 将迁入 DWM，届时将关闭 Plasma 6 并按问卷启用 tty 自动登录 + startx
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # 注意：NixOS wiki 强调 dwm 绝不可放入 environment.systemPackages，否则 override 无法生效
}
