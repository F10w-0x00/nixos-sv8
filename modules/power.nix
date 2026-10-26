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

      # 精准 USB 电源管理：开启全局自动休眠，仅将 2.4G 接收器列入黑名单保活
      USB_AUTOSUSPEND = 1;
      USB_DENYLIST = "3151:3020"; # 仅锁定 2.4G 鼠标接收器，防止鼠标休眠丢帧
    };
  };

  # ── 3. Udev 精准靶向供电规则 ────────────────
  # 仅针对 2.4G 鼠标无线接收器（3151:3020）保持活跃供电，放行主控制器与内置外设休眠
  services.udev.extraRules = ''
    ACTION=="add|change", SUBSYSTEM=="usb", ATTR{idVendor}=="3151", ATTR{idProduct}=="3020", ATTR{power/control}="on"
  '';
}
