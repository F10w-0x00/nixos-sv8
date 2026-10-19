# modules/power.nix — 电源管理与功耗释放策略
# 作用：TLP 能效调度、睡眠模式基线、throttled 功耗墙调优与编译性能释放
# 依赖：无
# 目录：1. 睡眠模式与合盖锁屏  2. TLP 电源管理策略  3. 功耗墙策略 (方案 A 与 方案 B 快速切换)
{ ... }:

let
  # ── 能效与功耗调优参数区 ────────────────────────
  # EPP 能效偏好：插电时 balance_performance，电池时 balance_power
  eppOnAc = "balance_performance";
  eppOnBat = "balance_power";

  # CPU 调频策略（Intel P-state 驱动标准 governor 为 powersave，实际频率由 EPP 动态调控）
  governorOnAc = "powersave";
  governorOnBat = "powersave";

  # throttled 功耗释放参数 (针对 Core i7-8665U 编译性能优化)
  # [SV8] 针对插电 (AC) 编译场景：解开 10W 原厂钳制至 20W (Intel ARK 标称 15W，cTDP-up 为 25W)
  acPl1 = 20; # AC 持续功耗 (W)
  acPl2 = 40; # AC 短时爆发功耗 (W)
  acTripTemp = 85; # AC 核心温度保护墙 (°C)

  # [SV8] 针对电池 (BAT) 场景：保持 15W 标称功耗，兼顾移动办公续航
  batPl1 = 15; # 电池持续功耗 (W)
  batPl2 = 25; # 电池短时爆发功耗 (W)
  batTripTemp = 80; # 电池核心温度保护墙 (°C)
in
{
  # ── 1. 睡眠模式与合盖锁屏 ────────────────────
  # [SV8] 本机经实测支持 s2idle 与 deep 两种睡眠模式（实测见 NOTES.md）
  # 当前保持系统默认；若需要深度 S3 睡眠可开启下方选项
  # [ALT] boot.kernelParams = [ "mem_sleep_default=deep" ];

  # 开启 UPower 硬件供电与电池状态守护服务
  services.upower.enable = true;

  # 合盖与电源键行为：统一为挂起睡眠（由 xss-lock 自动联动 slock 锁屏保护隐私）
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend";
    HandlePowerKey = "suspend";
  };

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

  # ── 3. 功耗墙策略 (方案 A 与 方案 B 快速切换) ──
  # [SV8] 方案 A vs 方案 B 双方案保留说明（详见 NOTES.md §7 与 prompt.md）：
  # • 方案 A（原厂保守 10W）：极度冷凉、静音、超长续航，适合移动办公/放膝盖上
  # • 方案 B（性能释放 20W）：插电编译加速，全核睿频 2.4~3.0GHz，适合长时间编译
  # 可改：设置 enable = true 即为方案 B；修改为 false 即秒切回方案 A
  # [RISK] 方案 B 满载编译时风扇会明显加速，底壳温度 55~65°C；回退办法：改 false 或选上一代
  services.throttled = {
    enable = false; # 可改：true (方案 B 性能) / false (方案 A 冷凉静音)
    extraConfig = ''
      [GENERAL]
      Enabled: True
      Update_Rate_s: 5

      [BATTERY]
      Update_Rate_s: 30
      PL1_Tdp_W: ${toString batPl1}
      PL1_Duration_s: 28
      PL2_Tdp_W: ${toString batPl2}
      PL2_Duration_S: 0.002
      Trip_Temp_C: ${toString batTripTemp}

      [AC]
      Update_Rate_s: 5
      PL1_Tdp_W: ${toString acPl1}
      PL1_Duration_s: 28
      PL2_Tdp_W: ${toString acPl2}
      PL2_Duration_S: 0.002
      Trip_Temp_C: ${toString acTripTemp}
    '';
  };
}
