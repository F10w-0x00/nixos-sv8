# modules/power.nix — 电源管理与能效策略
# 包含：深度睡眠 (S3 deep)、TLP 能效调度与低功耗调优（固化 10W 冷凉静音与长续航）
{ ... }:

let
  # ── EPP 能效与调频策略 ────────────────────────
  # Intel P-state 驱动标准：governor 设为 powersave，实际频率由 EPP 动态调谐
  governorOnAc = "powersave";
  governorOnBat = "powersave";

  # 插电时兼顾响应与温度，电池时最大化能效与续航
  eppOnAc = "balance_performance";
  eppOnBat = "balance_power";
in
{
  # ── 1. 深度睡眠与电源事件 ────────────────────
  # 强制使用 S3 deep 深度睡眠，切断 CPU 与大部分外设供电，根除休眠偷跑电
  boot.kernelParams = [ "mem_sleep_default=deep" ];

  services.upower.enable = true;

  # 合盖与轻按电源键行为：统一挂起睡眠（由 xss-lock 自动联动 slock 锁屏）
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

      # USB 全局自动挂起（外接 2.4G 鼠标接收器加入白名单，防止误休眠产生延迟）
      USB_AUTOSUSPEND = 1;
      USB_DENYLIST = "3151:3020";
    };
  };
}
