# modules/power.nix — 电源管理与功耗释放策略
# 包含：深度睡眠、TLP 能效调度、功耗墙双方案（方案 A 10W 冷凉静音 / 方案 B 20W 满血性能）
{ ... }:

let
  # ── 功耗调优与释放参数 ────────────────────────
  # EPP 能效策略：插电时偏重性能，电池时偏重续航
  eppOnAc = "balance_performance";
  eppOnBat = "balance_power";

  governorOnAc = "powersave";
  governorOnBat = "powersave";

  # 方案 B 满血功耗墙参数 (针对 Core i7-8665U 编译加速)
  acPl1 = 20; # 插电持续功耗 (W)
  acPl2 = 40; # 插电短时爆发功耗 (W)
  acTripTemp = 85; # 插电温控上限 (°C)

  batPl1 = 15; # 电池持续功耗 (W)
  batPl2 = 25; # 电池短时爆发功耗 (W)
  batTripTemp = 80; # 电池温控上限 (°C)
in
{
  # ── 1. 深度睡眠与电源事件 ────────────────────
  # 强制使用 S3 deep 深度睡眠，杜绝休眠偷跑电
  boot.kernelParams = [ "mem_sleep_default=deep" ];

  services.upower.enable = true;

  # 合盖与轻按电源键行为：统一挂起睡眠（由 xss-lock 自动联动 slock 锁屏）
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend";
    HandlePowerKey = "suspend";
  };

  # ── 2. TLP 能效调度 ──────────────────────────
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = governorOnAc;
      CPU_SCALING_GOVERNOR_ON_BAT = governorOnBat;
      CPU_ENERGY_PERF_POLICY_ON_AC = eppOnAc;
      CPU_ENERGY_PERF_POLICY_ON_BAT = eppOnBat;

      PCIE_ASPM_ON_AC = "default";
      PCIE_ASPM_ON_BAT = "powersupersave";

      WIFI_PWR_ON_AC = "off";
      WIFI_PWR_ON_BAT = "on";

      SOUND_POWER_SAVE_ON_AC = 0;
      SOUND_POWER_SAVE_ON_BAT = 1;

      # USB 全局自动挂起（外接 2.4G 鼠标接收器加入白名单，防止误休眠产生延迟）
      USB_AUTOSUSPEND = 1;
      USB_DENYLIST = "3151:3020";
    };
  };

  # ── 3. 功耗墙调度 (throttled) ────────────────
  # 功耗方案切换：
  # • enable = false：方案 A（原厂 10W），极度冷凉静音，超长续航
  # • enable = true ：方案 B（释放 20W），全核高频加速，适合大型项目编译
  services.throttled = {
    enable = false;
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
