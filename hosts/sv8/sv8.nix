# hosts/sv8/sv8.nix — Panasonic Let's Note CF-SV8 本机特有硬件配置
# 本文件是唯一的本机特有配置；换一台电脑本文件中所有设置均失效、有害或无意义
{
  config,
  pkgs,
  ...
}:

{
  # ── 1. 松下专有平台驱动与按键 ─────────────────
  # [SV8] 松下独占 WMI/ACPI 平台驱动，绑定机身特有热键（Fn 亮度/音量）、硬件接口；换其他品牌机器加载无意义
  boot.kernelModules = [
    "panasonic_laptop"
    "acpi_call"
  ];

  # ── 2. 松下 EC 原生静音温控 (acpi_call) ─────────
  # [SV8] 编译并加载 acpi_call 内核模块，接管松下独有 EC 嵌入式控制器温控通道
  boot.extraModulePackages = [ config.boot.kernelPackages.acpi_call ];

  # [SV8] 开机时向 EC 写入原厂静音曲线，消除待机蜂鸣声并放行待机 0 RPM 完全停转
  systemd.services.panasonic-fan-quiet = {
    description = "Panasonic Let's Note EC Silent Fan Profile";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-modules-load.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "panasonic-fan-quiet" ''
        ${pkgs.kmod}/bin/modprobe acpi_call 2>/dev/null || true
        if [ -e /proc/acpi/call ]; then
          # 写入松下原厂 Eco/Silent 静音温控曲线 (0x79 -> 0x02) 并放行低温 0 RPM 停转 (0x77 -> 0x00)
          echo '\_SB.PCI0.LPCB.EC0.EC88 0xB5 0x79 0x02 0x00' > /proc/acpi/call
          echo '\_SB.PCI0.LPCB.EC0.EC88 0xB5 0x77 0x00 0x00' > /proc/acpi/call
        fi
      '';
      RemainAfterExit = true;
    };
  };

  # [SV8] 睡眠唤醒后自动重新下发 EC 原生静音曲线，防止固件唤醒重置为性能保底高转速
  powerManagement.resumeCommands = ''
    if [ -e /proc/acpi/call ]; then
      echo '\_SB.PCI0.LPCB.EC0.EC88 0xB5 0x79 0x02 0x00' > /proc/acpi/call
      echo '\_SB.PCI0.LPCB.EC0.EC88 0xB5 0x77 0x00 0x00' > /proc/acpi/call
    fi
  '';

  # ── 3. 显示与 Intel 核显 ──────────────────────
  # [SV8] Intel Whiskey Lake Gen9 UHD 620 核显 VA-API 硬件解码器；AMD/Nvidia 机器不适用
  hardware.graphics.extraPackages = with pkgs; [
    intel-media-driver
    libvdpau-va-gl
  ];

  # [SV8] Intel 核显采用通用 modesetting 驱动，避免 xf86-video-intel 撕裂与独显冲突
  services.xserver.videoDrivers = [ "modesetting" ];

  # [SV8] 松下 CF-SV8 12.1 英寸 1920x1200 屏幕定制 1.5x 视觉缩放 (144 DPI)；通用模块默认回退 96
  services.xserver.dpi = 144;

  # ── 4. 松下经典圆盘触摸板 ────────────────────
  # [SV8] 禁用通用 libinput，改用 synaptics 驱动以原生支持圆盘边缘顺时针/逆时针旋转滚动
  services.libinput.enable = false;

  services.xserver.synaptics = {
    enable = true;
    tapButtons = true; # 轻触点击
    fingersMap = [
      1
      3
      2
    ]; # 单指左键、双指右键、三指中键
    buttonsMap = [
      1
      3
      2
    ];
    twoFingerScroll = true; # 保留标准双指平移滚动
    palmDetect = true; # 开启掌压防误触
    additionalOptions = ''
      Option "CircularPad" "on"
      Option "CircularScrolling" "on"
      Option "CircScrollTrigger" "0"
      Option "CircScrollDelta" "0.4"
      Option "CoastingSpeed" "0"
    '';
  };

  # ── 5. 睡眠策略与内核参数 ────────────────────
  # [SV8] 专有内核参数统一注入（保持原厂基线顺序：睡眠在前、显示防闪屏在后）
  boot.kernelParams = [
    # [SV8] §5 睡眠：强制 S3 deep 深度睡眠；CF-SV8 固件明确支持 S3，根除休眠漏电
    "mem_sleep_default=deep"
    # [SV8] §3 显示：禁用 Intel 核显 Panel Self Refresh (PSR)，杜绝屏幕偶发闪屏
    "i915.enable_psr=0"
    # [SV8] 禁用硬件与软件看门狗（Watchdog）定时器，消除 CPU 周期中断唤醒，加速开关机
    "nowatchdog"
  ];

  # [SV8] 彻底屏蔽 Intel 专有看门狗驱动模块，免除内核初始化与关机交互延迟
  boot.blacklistedKernelModules = [
    "iTCO_wdt"
    "mei_wdt"
    "intel_oc_wdt"
  ];

  # [SV8] 关机与重启时彻底禁用 systemd 硬件看门狗交互，实现瞬间切断断电
  systemd.settings.Manager = {
    RebootWatchdogSec = "0s";
  };

  # ── 6. 电池节点名称 ──────────────────────────
  # [SV8] 松下主板 ACPI 固件将机身电池命名为 BAT1（通用机型通常为 BAT0）
  my.batteryName = "BAT1";

  # ── 7. 内置光驱 (DVD+R 刻录支持) ─────────────
  # [SV8] 松下 CF-SV8 内置 9.5mm 超薄 SATA 刻录光驱 (HL-DT-ST DVDRAM GUD0N)
  # 赋予主用户直接免提权读写光驱设备 (/dev/sr0) 权限
  users.users.flynn.extraGroups = [ "cdrom" ];

  # ── 8. 本机特有硬件配套工具 ──────────────────
  # [SV8] 集中声明本机硬件专属工具（遵循 Nix 属性名唯一性语法要求）
  environment.systemPackages = with pkgs; [
    # §4 松下圆盘触摸板调试工具 (synclient / xinput)
    xf86-input-synaptics
    xinput
    # §7 内置光驱免提权刻录工具集 (growisofs / cdrkit / xorriso)
    dvdplusrwtools
    cdrkit # 原生提供 mkisofs 与 genisoimage，供 growisofs 实时打包目录直刻
    xorriso
  ];
}
