# modules/hardware-sv8.nix — 松下 CF-SV8 专有硬件适配
# 包含：Intel 微码、专有固件、松下内核驱动、ZRAM 压缩内存与 SSD 维护
{
  config,
  lib,
  pkgs,
  ...
}:

{
  # ── 1. 固件与微码 ────────────────────────────
  # 启用闭源设备固件（Wi-Fi、蓝牙所必需）与 Intel CPU 微码更新
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # ── 2. 松下专有驱动 ──────────────────────────
  # 加载 panasonic_laptop 驱动，支持机载功能热键、亮度与电池管理接口
  boot.kernelModules = [ "panasonic_laptop" ];

  # ── 3. 内存与存储优化 ────────────────────────
  # 启用 ZRAM 压缩内存交换，避免磁盘磨损并防止高负载场景下 OOM 假死
  zramSwap = {
    enable = true;
    memoryPercent = 50; # 使用最多 50% 内存作为动态压缩 swap
  };

  # 每周对固态硬盘执行 TRIM 清理，延长写入寿命
  services.fstrim = {
    enable = true;
    interval = "weekly";
  };
}
