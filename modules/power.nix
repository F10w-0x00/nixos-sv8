# modules/power.nix — 电源管理与睡眠
# 作用：电源策略骨架、睡眠模式配置
# 依赖：无
# 目录：1. 睡眠模式基线  2. 电源管理骨架
{ ... }:

{
  # ── 1. 睡眠模式基线 ──────────────────────────
  # [SV8] 本机经实测支持 s2idle 与 deep 两种睡眠模式（见 NOTES.md）
  # 阶段 1 保持默认；阶段 5 将实测 deep 与 s2idle 功耗差异再决定是否锁定 mem_sleep_default=deep
  # [ALT] boot.kernelParams = [ "mem_sleep_default=deep" ];

  # ── 2. 电源管理骨架 ──────────────────────────
  # 阶段 1 暂不启用 TLP 或额外限制，等待阶段 5 进行基线测量与压力测试
  # [ALT] services.tlp.enable = true;
}
