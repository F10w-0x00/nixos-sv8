# modules/hardware-sv8.nix — 松下 SV8 专有硬件适配
# 作用：CPU 微码、闭源固件、松下专有内核驱动、SSD TRIM 与 ZRAM
# 依赖：hosts/sv8/hardware-configuration.nix
# 目录：1. 固件与微码  2. 松下专有内核模块  3. 存储与内存优化
{
  config,
  lib,
  pkgs,
  ...
}:

{
  # ── 1. 固件与微码 ────────────────────────────
  # [SV8] 启用非自由固件（Wi-Fi/蓝牙等设备必须）与 Intel CPU 微码修复
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # ── 2. 松下专有内核模块 ──────────────────────
  # [SV8] 加载松下笔记本驱动，暴露热键、亮度与电池接口（/sys/devices/platform/panasonic_laptop）
  boot.kernelModules = [ "panasonic_laptop" ];

  # ── 3. 存储与内存优化 ────────────────────────
  # [SV8] 针对板载 16GB 内存启用 ZRAM 压缩内存交换，无磁盘磨损且防止重度多任务 OOM 假死
  zramSwap = {
    enable = true;
    memoryPercent = 50; # 可改：使用最多 50% 内存作为压缩 swap 空间
  };

  # 定期对 SATA SSD 执行 TRIM 清理，保持长期读写寿命与性能
  services.fstrim = {
    enable = true;
    interval = "weekly";
  };
}
