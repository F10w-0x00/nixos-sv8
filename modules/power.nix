# modules/power.nix — 电源管理与睡眠策略
# 作用：TLP 省电优化、CPU 能效调度、睡眠模式基线、功耗限制说明
# 依赖：无
# 目录：1. 睡眠模式  2. TLP 电源管理策略  3. 功耗墙策略与备用解锁说明
{ ... }:

let
  # 电源调优参数区（针对 Intel Core i7-8665U 与松下移动办公设计）
  # EPP 能效偏好：插电时 balance_performance，电池时 balance_power（兼顾流畅响应与长续航）
  eppOnAc = "balance_performance";
  eppOnBat = "balance_power";

  # CPU 调频策略（Intel P-state 驱动标准 governor 为 powersave，实际频率由 EPP 动态调控）
  governorOnAc = "powersave";
  governorOnBat = "powersave";
in
{
  # ── 1. 睡眠模式 ──────────────────────────────
  # [SV8] 本机经实测支持 s2idle 与 deep 两种睡眠模式（实测见 NOTES.md）
  # 当前保持系统默认；若需要深度 S3 睡眠可开启下方选项
  # [ALT] boot.kernelParams = [ "mem_sleep_default=deep" ];

  # ── 2. TLP 电源管理策略 ───────────────────────
  # [SV8] 启用 TLP 高级电源管理，关闭互斥的 power-profiles-daemon
  services.tlp = {
    enable = true;
    settings = {
      # CPU 调频与 EPP 能效配置
      CPU_SCALING_GOVERNOR_ON_AC = governorOnAc;
      CPU_SCALING_GOVERNOR_ON_BAT = governorOnBat;
      CPU_ENERGY_PERF_POLICY_ON_AC = eppOnAc;
      CPU_ENERGY_PERF_POLICY_ON_BAT = eppOnBat;

      # PCIe 活动状态电源管理 (ASPM)
      PCIE_ASPM_ON_AC = "default";
      PCIE_ASPM_ON_BAT = "powersupersave";

      # Wi-Fi 节能模式
      WIFI_PWR_ON_AC = "off";
      WIFI_PWR_ON_BAT = "on";

      # 声卡省电超时（秒）
      SOUND_POWER_SAVE_ON_AC = 0;
      SOUND_POWER_SAVE_ON_BAT = 1;

      # USB 自动挂起：为防止外接鼠标或无线接收器掉线延迟，默认关闭全局挂起
      USB_AUTOSUSPEND = 0;
    };
  };

  # ── 3. 功耗墙策略与备用解锁说明 ───────────────
  # [SV8] 用户决策（2026-10-19）：保持松下原厂 10W 保守策略，追求极致温控、静音与长续航。
  # [ALT] 未来若需解锁 Intel 标称 15W/20W 满血性能，取消下方注释并 rebuild 即可：
  # [RISK] 满载时底壳温度可能升至 65~70°C；详见 NOTES.md 阶段 5 记录
  # services.throttled = {
  #   enable = true;
  #   extraConfig = ''
  #     [GENERAL]
  #     Enabled: True
  #     [BATTERY]
  #     PL1_Tdp_W: 15
  #     PL2_Tdp_W: 25
  #     Trip_Temp_C: 80
  #     [AC]
  #     PL1_Tdp_W: 20
  #     PL2_Tdp_W: 40
  #     Trip_Temp_C: 85
  #   '';
  # };
}
