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

      # 彻底关闭 USB 自动休眠并锁定 2.4G 接收器与主控制器
      USB_AUTOSUSPEND = 0;
      USB_DENYLIST = "3151:3020"; # 锁定 2.4G 鼠标接收器
      RUNTIME_PM_DENYLIST = "00:14.0"; # 锁定 Intel xHCI USB 主控制器，禁止 PCI 运行时休眠
    };
  };

  # ── 3. 内核级与 udev 物理防休眠锁 ───────────
  # 内核级全局关闭 USB 自动休眠（usbcore.autosuspend=-1）
  boot.kernelParams = [ "usbcore.autosuspend=-1" ];

  # 强制锁定 USB 主控制器与 2.4G 接收器供电，根除间歇性停滞卡死
  services.udev.extraRules = ''
    # 强制保持 Intel xHCI USB 控制器处于活跃供电状态 (power/control = on)
    ACTION=="add|change", SUBSYSTEM=="pci", ATTR{class}=="0x0c0330", ATTR{power/control}="on"
    # 强制保持所有 USB 根集线器 (Hubs) 常开，禁止休眠 (power/control = on)
    ACTION=="add|change", SUBSYSTEM=="usb", ATTR{bDeviceClass}=="09", ATTR{power/control}="on"
    # 强制保持 2.4G 鼠标无线接收器常开，禁止休眠
    ACTION=="add|change", SUBSYSTEM=="usb", ATTR{idVendor}=="3151", ATTR{idProduct}=="3020", ATTR{power/control}="on"
  '';
}
