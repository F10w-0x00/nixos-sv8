# modules/power.nix — 通用电源管理与能效调度
# 包含：UPower 监控、logind 电源事件响应与 TLP 软硬件级节能策略
{ ... }:

let
  # ── EPP 能效与调频策略 ────────────────────────
  # CPU 调频标准：governor 采用 powersave，由 EPP 动态调谐响应与功耗
  governorOnAc = "powersave";
  governorOnBat = "powersave";

  # 插电兼顾响应与温度，离电最大化能效与续航
  eppOnAc = "balance_performance";
  eppOnBat = "balance_power";
in
{
  # ── 1. 电源状态与盒盖/按键事件 ───────────────
  services.upower.enable = true;

  # 合盖与轻按电源键统一执行挂起睡眠（由 xss-lock 自动联动 slock 锁屏）
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend";
    HandlePowerKey = "suspend";
  };

  # ── 2. TLP 能效调度与硬件级节能 ──────────────
  services.tlp = {
    enable = true;
    settings = {
      # CPU 调频与 EPP 能效策略
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

      # 彻底关闭 USB 自动休眠（根除 2.4G 无线鼠标接收器与外接外设延迟、卡顿与断连）
      USB_AUTOSUSPEND = 0;
    };
  };
}
