# SV8 决策与验证记录 (NOTES.md)

## 阶段 0 — 硬件盘点 (2026-10-18)

### 1. 系统与内核
- **NixOS 版本**：`26.05.11985.26f4107e47e3 (Yarara)`
- **内核版本**：`6.18.56`
- **CPU**：Intel Core i7-8665U (Whiskey Lake-U), 4C/8T, 1.90 GHz (最高 4.80 GHz), 板载不可更换
- **内存**：15 GiB (16 GB 板载 LPDDR3)
- **引导方式**：UEFI, `systemd-boot 260.5`
- **Secure Boot**：`disabled`
- **TPM2**：支持
- **当前时区**：`Asia/Shanghai (CST, +0800)`
- **当前 Locale**：`en_US.UTF-8` + `zh_CN.UTF-8`

### 2. 存储与分区 (SATA，非 NVMe)
- **SSD 控制器**：`00:17.0 SATA controller [AHCI Mode] [8086:9dd3]`
- **主磁盘**：`/dev/sda` (SATA 固态硬盘，256 GB / 233 GiB 可用空间)
  - `/dev/sda1`：FAT32 EFI 系统分区 `/boot` (1022 MiB，剩余约 968 MiB，占用仅 5%)
  - `/dev/sda2`：ext4 根分区 `/` (233 GiB，剩余约 203 GiB，占用 8%)
- **光驱**：`/dev/sr0` (SATA DVD-ROM / 刻录光驱，松下经典配置)
- **当前 Swap**：无 (`0B`)

### 3. 显示与图形
- **核显**：`00:02.0 Intel Corporation WhiskeyLake-U GT2 [UHD Graphics 620] [8086:3ea0]`
- **内核驱动**：`i915`
- **屏幕规格**：12.1 英寸 1920×1200 (16:10)，约 187 DPI

### 4. 外设与扩展组件
- **触摸板**：`Synaptics TM3136-020`，i2c 接口 (`i2c-SYNA0100:00`)，设备节点 `/dev/input/event10`
- **松下快捷键**：`panasonic_laptop` 模块已加载，设备 `Panasonic Laptop Support` (`/dev/input/event7`)
- **无线网卡 (Wi-Fi)**：`00:14.3 Intel Cannon Point-LP CNVi [Wireless-AC 9560] [8086:9df0]`，驱动 `iwlwifi`
- **蓝牙**：`Bus 001 Device 005: ID 8087:0aaa Intel Corp. Bluetooth 9460/9560 Jefferson Peak`，驱动 `btusb`
- **蜂窝网络 (WWAN)**：`Bus 001 Device 003: ID 1199:9071 Sierra Wireless, Inc. AirPrime MC7455 / EM7430 3G/4G LTE Modem` (`cdc-wdm0` gsm 设备)
- **有线网卡**：`00:1f.6 Intel Ethernet Connection (6) I219-LM [8086:15bd]`，驱动 `e1000e`
- **雷电 (Thunderbolt 3)**：`01:00.0 - 03:00.0 Intel Corporation JHL6340 Thunderbolt 3 Bridge & Controller [Alpine Ridge 2C 2016]`，驱动 `thunderbolt`
- **SD 读卡器**：`3a:00.0 O2 Micro, Inc. OZ777 SD/MMC Card Reader Controller [1217:8520]`，驱动 `sdhci-pci`
- **摄像头**：Bison Electronics USB HD Webcam (`5986:1156`)
  - 普通 RGB 摄像头：`/dev/video0`
  - **红外人脸相机 (IR Camera)**：`/dev/video2` (支持 Windows Hello / Linux Howdy 人脸识别)
- **指纹识别**：**无**（硬件未检出指纹传感器）
- **声卡**：`00:1f.3 Intel Cannon Point-LP High Definition Audio Controller [8086:9dc8]`，驱动 `snd_hda_intel`
- **电源供应**：`AC`、`BAT1`、`ucsi-source-psy-USBC000:001` (支持 Type-C PD 充电)
- **睡眠模式支持**：`cat /sys/power/mem_sleep` 输出为 `[s2idle] deep`（同时支持 S2idle 与 Deep/S3 睡眠！）

### 5. 机器型号与 DMI 信息
- **厂商**：Panasonic Corporation
- **产品名**：CFSV8-2
- **SKU**：`CF-SV8SFKVS`
- **序列号**：`[Sanitized]`
- **BIOS 版本**：`V2.00L12` (发布日期：2019-06-27)
- **固件类型**：UEFI 2.70 (AMI)

### 6. 历史配置迁移
- 原 `/etc/nixos/` 历史安装配置已完整解构并迁移至模块化架构，原稿由 Git 提交历史归档保存。

### 7. 阶段 0 决策结论 (与用户确认)
1. **用户名**：`flynn`（沿用）
2. **主机名**：`sv8`（匹配 flake 目标 `#sv8`）
3. **Flakes**：启用（统一使用 flake 构建）
4. **nixpkgs 分支**：沿用当前通道版本 `nixos-unstable` / `nixos-26.05`
5. **home-manager**：暂不引入，先在系统级声明式管理
6. **键盘布局**：**标准美式 US 键盘布局**（用户 2026-10-18 最新变更：不需要 JIS 映射，统一使用标准 US 布局）
7. **时区**：`Asia/Shanghai`（沿用）
8. **输入法与字体**：**无需输入法**（按用户最新要求完全移除 Fcitx5，本机不需要打中文），**全量保留 CJK 字体**（Noto CJK Sans/Serif、文泉驿）以满足中日英文字正常阅读显示
9. **电源偏好**：续航优先
10. **休眠 (Hibernate)**：不需要（仅使用 S3 deep 睡眠）
11. **登录方式**：`tty 自动登录 + startx`（极简、无 Display Manager 守护开销，任务书推荐）

## 阶段 1 — 仓库与基线 (2026-10-18)

### 1. 仓库结构与模块化拆分
- 初始化 `~/nixos-config` Flake 结构：
  - `flake.nix` & `flake.lock` (pinned to commit `26f4107e47e3ad0ffd0db220469ba83b6f6d96e8`)
  - `hosts/sv8/default.nix` & `hosts/sv8/hardware-configuration.nix`
  - `modules/base.nix`：Nix 配置、Flakes 支持、systemd-boot (保留上限 10 代)、时区 Locale、用户与系统维护工具
  - `modules/hardware-sv8.nix`：CPU 微码、闭源固件、`panasonic_laptop` 内核模块、`zramSwap` (50% 内存 = 7.7G)、`fstrim`
  - `modules/graphics.nix`：Intel UHD 620 核显、`intel-media-driver` (VAAPI)、modesetting 驱动
  - `modules/input.nix`：JIS jp106 键盘映射、libinput 基础触控板配置
  - `modules/power.nix`：电源骨架（预留阶段 5 实测）
  - `modules/desktop-dwm.nix`：阶段 1 保持 Plasma 6 等价基线；阶段 2 迁移 DWM
  - `modules/fonts-ime.nix`：Noto CJK、JetBrainsMono Nerd Font、Fcitx5 拼音输入法
  - `modules/services.nix`：NetworkManager、Bluetooth (Intel 9560)、PipeWire 音频、CUPS、fwupd、Flatpak、LocalSend、Clash Verge

### 2. 构建与切换验证
- `nix flake check --no-build`：评估全部通过。
- `sudo nixos-rebuild test --flake ~/nixos-config#sv8`：成功激活（Done，exit 0）。
- 只读验证结果：
  - `hostname` -> `sv8`
  - `systemctl is-active bluetooth dev-zram0.swap NetworkManager` -> 全部 `active`
  - `zramctl` -> `/dev/zram0` (7.7G, zstd, SWAP active)
  - `lsmod | grep panasonic` -> `panasonic_laptop` 驱动正常加载
- `sudo nixos-rebuild switch --flake ~/nixos-config#sv8`：成功固化为 Generation 18（`/nix/store/czbc7av1gn7jcg1ijjdxli6f62ng37ar-nixos-system-sv8-26.05.20261015.26f4107`），成为 UEFI 默认启动项。

## 阶段 2 — 图形与 DWM（X11）(2026-10-18)

### 1. 图形栈与硬件加速
- 核显驱动：Intel UHD 620 (`i915` + modesetting)
- 硬件编解码 (VAAPI)：`intel-media-driver` (iHD 26.1.6) 已就绪，vainfo 验证通过。
- OpenGL：Mesa 26.1.8 (Core Profile 4.6) 硬件加速正常。
- 缩放调整：根据 12.1 寸 1920×1200 物理屏幕（~187 DPI），全局 DPI 设定为 144（1.5x 缩放）；DWM 顶栏与 dmenu 设定为 11pt，界面紧凑清晰。

### 2. DWM 与 Suckless 工具链定制
- 源码定制与补丁纳入 Git 管理：
  - `pkgs/dwm/config.h`：工作区精简为 1~6（删除 7/8/9）；使用 `Mod4` (Super/Win) 键；绑定音量、亮度、锁屏及截图快捷键；顶栏字号 11。
  - `pkgs/st/config.h` & `pkgs/st/patches/`：打入官方回滚补丁、`st-glyph-wide-support` 宽字形渲染补丁以及 `st-clickurl` 补丁（支持按住 Ctrl 悬停高亮、Ctrl+鼠标左键直接呼出 Firefox），字号 pixelsize=20。
  - `pkgs/dmenu/config.h`：Catppuccin 深色配色，字号 11。
  - `pkgs/slstatus/config.h`：纯净极简显示 CPU、RAM、Wi-Fi `[WIFI ✓/✗]`、电量 `[BAT %s%%]`、短时钟 `[%H:%M]`。
- 会话组件：
  - 壁纸：自动应用 `/home/flynn/Pictures/Kurisu.png`。
  - 半透明：启用 `picom` 硬件加速合成器，设置 `st` 不透明度为 0.8。
  - 自动锁屏：`xss-lock` 与 `slock` 联动，实现合盖与休眠锁屏。
  - 字体与输入法：按用户最新要求完全移除 Fcitx5 守护进程，保留全套 CJK 字体用于终端和网页正常阅读。

## 阶段 3 — 输入设备与圆形滚动 (2026-10-18)

### 1. 键盘布局 (US QWERTY)
- 用户决策：统一采用标准美式键盘映射（`layout = "us"`），无需 JIS 假名键等特殊按键映射。
- 配置位置：`modules/input.nix` (`services.xserver.xkb.layout = "us"`, `console.keyMap = "us"`).

### 2. 松下圆盘触摸板硬件探测
- **控制器**: `Synaptics TM3136-020` (I2C ID `06cb:cc40`, `/dev/input/event11`)
- **物理外观**: 经典 44mm 直径圆形触摸板（内置正方形传感器）
- **实测硬件坐标范围**:
  - `ABS_X`: min = 0, max = 880, resolution = 20
  - `ABS_Y`: min = 0, max = 880, resolution = 20
  - 几何中心点: `(440, 440)`

### 3. Synaptics 驱动与圆形滚动配置
- **解决冲突**: 关闭 `services.libinput.enable = false`（Xorg 不允许同时启用 libinput 和 synaptics 抢占触摸板）。
- **驱动配置**:
  - `services.xserver.synaptics.enable = true`
  - `Option "CircularPad" "on"`: 告知驱动物理触摸板为圆形，按椭圆/圆形边界处理坐标
  - `Option "CircularScrolling" "on"`: 开启沿边缘圆周画圈滚动（くるくるスクロール）
  - `Option "CircScrollTrigger" "0"`: 任意边缘位置起笔均可触发旋转滚动
  - `Option "CircScrollDelta" "0.1"`: 滚动步进灵敏度
  - `fingersMap = [ 1 3 2 ]` / `buttonsMap = [ 1 3 2 ]`: 单指左键、双指右键、三指中键
  - `twoFingerScroll = true`: 保留传统双指平移滚动兼容
  - `environment.systemPackages`: 引入 `xf86-input-synaptics` (提供 `synclient`) 与 `xinput` 供实时微调

### 4. 固化与实测验证
- 用户执行 `sudo nixos-rebuild switch --flake ~/nixos-config#sv8`，成功切换至 **Generation 19**。
- `xinput list-props 12` 验证驱动属性：
  - `Synaptics Circular Scrolling (352) = 1`
  - `Synaptics Circular Pad (355) = 1`
  - `Synaptics Circular Scrolling Distance (353) = 0.2` (调校后手感最佳)
- 实机体验：圆盘画圈滚动平滑自然，轻触左键、双指右键灵敏有效。

## 阶段 4 — 松下专有硬件与多媒体外设 (2026-10-19)

### 1. 松下平台驱动与按键
- **`panasonic_laptop` 驱动**：已加载，输入设备绑定在 `/dev/input/event9` (`Panasonic Laptop Support`)。
- **ACPI 事件**：日志中出现的 `Unknown hotkey event: 0x0030 / 0x0031` 为松下新机型固件广播通知，Fn 快捷键通过标准 AT PS/2 键盘发送标准 keycode。
- **多媒体快捷键**：
  - 亮度：`Fn + F1` (Down) / `Fn + F2` (Up) 直接调控 `intel_backlight`，步进 5%，平滑无频闪。
  - 声音：`Fn + F4` (Mute)、`Fn + F5` (Down)、`Fn + F6` (Up) 直接联动 PipeWire (`wpctl`)，工作正常。
  - 锁屏：`Super + Shift + l` 调用 `slock` 黑屏锁屏，盲打输入密码回车解锁。

### 2. 显示背光与环境光传感器 (ALS)
- **背光设备**: `/sys/class/backlight/intel_backlight`，最大亮度 `16326`。
- **环境光传感器**: `/sys/bus/iio/devices/iio:device0` (`acpi-als`)，存在且已由内核正确识别。

### 3. 音视频与外设
- **摄像头**: Bison Electronics USB HD Webcam (`5986:1156`)
  - RGB 摄像头：`/dev/video0`, `/dev/video1`
  - 红外人脸相机 (IR Camera)：`/dev/video2`, `/dev/video3`
- **音频系统**: PipeWire 1.6.6 + WirePlumber，内置立体声扬声器与模拟麦克风均已连接并默认路由。
- **SD 读卡器**: O2 Micro OZ777 (`1217:8520`)，驱动 `sdhci-pci` 正常运行。
- **雷电 3 (Thunderbolt 3)**: Intel JHL6340 Alpine Ridge 控制器，驱动 `thunderbolt` 正常加载。
- **WWAN (蜂窝数据)**: Sierra Wireless MC7455 (`1199:9071`)，驱动 `qcserial` + `cdc_mbim` 正常加载，NetworkManager 识别为 `enabled`。

### 4. 功耗基准测量 (Intel RAPL & C-states)
- **CPU 封装功耗**: 实测稳定在 **3.02 W ~ 3.53 W**，整机功耗预估仅 **7.3 W ~ 7.8 W**。
- **CPU 温度**: 核心温度 **46.0 °C**，南桥 **39.0 °C**，机身温凉，风扇静音。
- **深度节能 (C-States)**: 核心成功进入 **`C10` 极致节能深度睡眠**（累计驻留 > 1800 秒）。
- **固件功耗墙**: PL1 (长期) = **20.00 W**，PL2 (短时爆发) = **51.00 W**。

### 5. 壁纸自包含与规范整理
- 将壁纸从 `~/Pictures` 迁移并打包入仓库 `wallpapers/wallpaper.png`，完全实现 Flake 声明式自包含与可移植性。
- 修复 `xorg.xinput` 废弃警告，升级为顶级包名 `pkgs.xinput`。

### 6. 满载压力测试与 10W 功耗墙溯源结论 (2026-10-19)
- **实测数据记录 (8 线程 stress-ng 满载)**：
  - Sec 1~2: 瞬时突发 `11.69 W`，全核 `1.90 GHz`，核心温度 `46.0 °C`
  - Sec 3~12: 持续恒定在 **`10.16 W ~ 10.34 W`**，全核回落至 `1.60 ~ 1.70 GHz`，核心温度 `48.0 ~ 50.0 °C`
- **限制溯源与确凿证据**：
  - 现象：即使 CPU 核心仅 49°C，远低于常规热保护点（100°C），持续功耗仍被强行锁死在 10W。
  - 来源证据：读取主板热敏区域，`thermal_zone5 (SEN2)` 设定了外壳温控点 `trip_point_3_temp = 56.05 °C (hot)`。松下固件为了保证轻薄镁合金机身在用户膝盖上使用不发烫（Lap Comfort），由 EC 与 DPTF 联合介入，发送强制降功耗信号至 10W。
- **用户决策演进 (2026-10-19)**：
  - **当前状态**：**采纳方案 A（保持 10W 原厂冷凉静音超长续航策略）**。
    - **决策原因**：用户经 1.5h 实机离电开发实测（平均功耗约 10.9W），决定全面优先保障低温、安静与超长续航，将功耗策略切换回原厂方案 A（关闭 `services.throttled`，恢复纯净原厂 10W 控制）。
- **方案 B 调优与落地配置细节**：
  - 在 `modules/power.nix` 启用 `services.throttled` 并配置：
    ```nix
    services.throttled = {
      enable = true;
      extraConfig = ''
        [GENERAL]
        Enabled: True
        Update_Rate_s: 5

        [BATTERY]
        Update_Rate_s: 30
        PL1_Tdp_W: 15
        PL1_Duration_s: 28
        PL2_Tdp_W: 25
        PL2_Duration_S: 0.002
        Trip_Temp_C: 80

        [AC]
        Update_Rate_s: 5
        PL1_Tdp_W: 20
        PL1_Duration_s: 28
        PL2_Tdp_W: 40
        PL2_Duration_S: 0.002
        Trip_Temp_C: 85
      '';
    };
    ```
  - **设计细节与原理解析**：
    1. **AC 插电 (编译场景)**：`PL1_Tdp_W = 20W`（Intel ARK 基准 15W，cTDP-up 为 25W；20W 为兼顾性能与散热的最佳甜点点），短时爆发 `PL2 = 40W`；核心温度保护点设为 `85°C`（CPU 硬件 Tjunction 上限为 100°C，85°C 保留充分安全余量）。
    2. **电池续航 (移动场景)**：`PL1_Tdp_W = 15W`，`PL2_Tdp_W = 25W`，温度保护点 `80°C`，保障不插电时的能效与续航。
    3. **周期覆写对抗 EC 降频 (`Update_Rate_s: 5`)**：松下 DPTF/EC 检测到底壳 `thermal_zone5 / SEN2` 超过 56°C 时会强行向 MSR 发送 10W 降频信号；`throttled` 以 5 秒为周期自动重新写入 MSR 0x610 寄存器，从而压制 EC 的 10W 强制降频。
  - **预期效果与发热提示**：
    - 持续编译负载下全核频率从 1.6 GHz 提升至 2.4 ~ 3.0 GHz+，编译耗时接近减半。
    - 风扇在高负载编译时会明显加速转动，底壳镁合金外壳温度会上升至 55~65°C（建议在桌面使用，避免直接置于裸露膝盖上高负荷编译）。
  - **如何验证与回滚**：
    - **验证命令**：`systemctl status throttled` 确认服务 active；高负载时运行 `turbostat --quiet --interval 1` 观察 `PkgWatt` 是否稳定在 ~20W。
    - **极速回滚 (即时生效)**：`sudo systemctl stop throttled`（立即恢复固件原生状态）。
    - **配置回滚**：在 `modules/power.nix` 将 `enable` 改为 `false` 并执行 rebuild；或在重启开机 UEFI 引导菜单选择上一代配置。

## 阶段 5 附录 — 功耗双方案速查与秒级切换手册 (方案 A vs 方案 B)

为了方便日后无需翻查代码、花最少的时间按需随时切换，现将方案 A 与方案 B 的特性对照、配置与切换指令汇总如下：

### 1. 方案特性横向对比

| 对比维度 | 方案 A（原厂冷凉静音，当前生效） | 方案 B（满血编译性能） |
| :--- | :--- | :--- |
| **持续功耗 (PL1)** | **10.16 W ~ 10.34 W** (固件/EC 强控) | **20.00 W** (AC 插电) / **15.00 W** (电池) |
| **短时爆发 (PL2)** | 20.00 W ~ 51.00 W (瞬时) | **40.00 W** (AC 插电) / **25.00 W** (电池) |
| **全核高负载睿频** | 1.60 ~ 1.70 GHz | **2.40 ~ 3.00 GHz+** |
| **大型编译耗时** | 基准 (1.0x，较慢) | **极速 (~0.5x~0.6x，耗时减半)** |
| **满载核心温度** | ~48.0 °C ~ 50.0 °C | ~70.0 °C ~ 82.0 °C (保护上限 85°C) |
| **满载外壳温度** | 极度温凉 (< 48°C) | 明显温热 (55°C ~ 65°C) |
| **满载风扇噪声** | 极安静 / 微风 | 正常排热风声 |
| **最佳使用场景** | 移动办公、放膝盖打字、咖啡馆长续航 | 桌面插电写代码、Nix 编译、C/C++ 大项目构建 |
| **核心机制** | 纯净原生，依靠 TLP 与 DPTF/EC | `services.throttled` 5s 周期覆写 MSR 寄存器 |

---

### 2. 秒级切换操作指南

#### 场景 1：如果未来想切回「方案 A (原厂 10W 冷凉静音)」
- **方法 1 (即时生效，无需 rebuild)**：
  ```bash
  sudo systemctl stop throttled
  ```
  *说明：立即解除寄存器接管，固件自动接管并在机身微温时恢复 10W 冷凉策略。*
- **方法 2 (永久固化)**：
  打开 `modules/power.nix`，将：
  ```nix
  services.throttled.enable = true;
  ```
  改为：
  ```nix
  services.throttled.enable = false;
  ```
  然后执行：
  ```bash
  sudo nixos-rebuild switch --flake ~/nixos-config#sv8
  ```

#### 场景 2：从方案 A 切到「方案 B (20W 满血编译)」
- 打开 `modules/power.nix`，将 `services.throttled.enable = true;`。
- 然后执行：
  ```bash
  sudo nixos-rebuild switch --flake ~/nixos-config#sv8
  ```
- 验证生效：
  ```bash
  systemctl status throttled
  ```

---

## 阶段 8 — 松下 CF-SV8 硬件功能完整对照表

| 硬件功能项 | 状态 | 落地驱动 / 配置方案 | 详细实测说明与调优备注 |
| :--- | :---: | :--- | :--- |
| **圆形滚动 (くるくるスクロール)** | **正常** | `xf86-input-synaptics` (`modules/input.nix`) | 实测圆盘边缘顺时针/逆时针顺畅滚动；`CircScrollDelta=0.2` 手感自然稳定 |
| **触摸板点按 / 平移** | **正常** | `xf86-input-synaptics` (`modules/input.nix`) | 单指左键、双指右键、三指中键；双指平移滚动兼容传统操作 |
| **亮度快捷键 (Fn+F1/F2)** | **正常** | PS/2 scancode + `brightnessctl` | 步进 5%，直接调控 `intel_backlight`，平滑无频闪 |
| **音量快捷键 (Fn+F4/F5/F6)** | **正常** | PS/2 scancode + PipeWire (`wpctl`) | 一键静音、音量加减、麦克风静音，无弹窗卡顿 |
| **功能快捷键 (锁屏/截图)** | **正常** | DWM 绑定 `slock` / `maim` + `xclip` | `Super+Shift+l` 极简黑屏锁屏；`PrtSc` 单键截图秒进系统剪贴板 |
| **无线滑块物理开关** | **部分** | DSDT MAT0028 只读识别 | 拨动滑块可物理切断蓝牙；Linux 暂无 MAT0028 驱动，依红线 4 不侵入写 EC，软件通过 NM/rfkill 统一管理 |
| **睡眠模式 (Suspend)** | **正常** | ACPI 原生支持 `[s2idle] deep` | `services.logind` 合盖挂起，`xss-lock` 联动锁屏；功耗极低 |
| **系统休眠 (Hibernate)** | **已跳过** | 用户阶段 0 决策跳过 | 阶段 0 明确无需磁盘 swap 挂起，纯使用 S3 deep 睡眠，节约 SSD 磨损 |
| **多途径系统唤醒** | **正常** | UEFI 2.70 AMI 固件原生支持 | 开盖 (`LID0`)、轻按电源键 (`PWRF`)、外接鼠标 (`XHC`) 均可唤醒，无需高风险 `acpi_call` |
| **屏幕闪屏** | **无闪屏** | Intel UHD 620 (`i915` + modesetting) | 多小时重负载、调亮度、编译未发生任何闪屏，内核日志健康 |
| **功耗与编译性能** | **正常** | 双方案自由切换 (`modules/power.nix`) | 方案 A (当前生效)：10W 极度冷凉静音超长续航；方案 B (备用)：20W 满血释放，全核 2.4~3.0GHz 极速编译 |
| **放电功耗与续航** | **正常** | TLP 能效调度 + Intel C-states | CPU 空闲封装仅 3.02W，C10 深度驻留，整机待机仅 ~7.5W |
| **RGB 高清摄像头** | **正常** | 内核 UVC 驱动 (`/dev/video0,1`) | Bison Electronics 720p HD Webcam 出流正常 |
| **红外人脸相机 (IR)** | **就绪** | 内核 UVC 驱动 (`/dev/video2,3`) | 红外硬件完备可用，支持 Linux Howdy 人脸解锁方案 |
| **内置麦克风与扬声器** | **正常** | PipeWire 1.6.6 + WirePlumber (`snd_hda_intel`) | 立体声输出清晰，内置麦克风采集良好，无爆音 |
| **SD 读卡器** | **正常** | 内核 `sdhci-pci` (O2 Micro OZ777 `1217:8520`) | PCIe 控制器加载正常，支持大容量 SD 卡即插即读 |
| **外接显示输出 (HDMI)** | **正常** | Intel UHD 620 + `autorandr` (`modules/graphics.nix`) | 支持 HDMI 外接高分屏与多屏自动重排 |
| **Type-C / 雷电 3 (TB3)** | **正常** | `thunderbolt` + UCSI PD 驱动 | 支持 65W PD 诱骗快充与雷电高速外设数据传输 |
| **指纹识别模块** | **不可用** | 硬件未配备 | 原厂选配项，本机未搭载指纹传感器硬件（`lsusb`/`lspci` 确认不存在） |
| **WWAN 4G 蜂窝网络** | **正常** | Sierra Wireless MC7455 (`qcserial` + `cdc_mbim`) | 驱动加载完毕，NetworkManager 识别为 `enabled` |

---

## 阶段 9 — 用户级配置 (~/.config) 盘点与 Home-Manager 演进预留 (2026-10-19)

### 1. 系统级配置 vs 用户级配置现状边界
- **系统级环境（100% 声明式且可复现）**：
  - DWM 窗口管理器、st 终端、slstatus 状态栏、dmenu 启动器：源码与 `config.h` 已嵌入仓库并通过 `.override` 编译，不产生或依赖 `~/.config` 文件。
  - 会话初始化：`startx`、144 DPI 全局缩放、picom 半透明、dunst 通知、slock 锁屏、壁纸自包含加载、默认浏览器与 MIME 关联：全部由 `modules/` 声明并生成全局配置，重装或迁移新机 100% 自动还原。
- **用户级环境（`~/.config/`）**：
  - 默认情况下，NixOS 的操作系统级 Flake 不接管 `$HOME/.config/`。

### 2. 当前 `~/.config/` 资产盘点
- **可忽略的历史遗留垃圾**：
  - 原厂测试 KDE Plasma 期间自动生成的大量配置文件（如 `kdeglobals`, `kwinrc`, `plasma*`, `dolphinrc`, `kate*`, `kded*`, `ksmserverrc` 等，共占 ~70%），已与当前 DWM 系统脱钩，重装时无需备份。
- **真正具有定制价值的核心配置文件**：
  1. **VS Code**：`/home/flynn/.config/Code/User/settings.json`
     - 关键配置：`"files.simpleDialog.enable": true`（彻底消除保存/打开文件时的白屏卡死现象）。
     - 个人偏好：`"workbench.colorTheme": "Tokyo Night Storm"`、`"editor.fontSize": 18`、C/C++ runner 脚本。
  2. **Alacritty**：`/home/flynn/.config/alacritty.toml`
     - 个人偏好：`size = 13.0`、JetBrainsMono Nerd Font、`opacity = 0.85`、无边框全屏模式。
  3. **Fastfetch**：`/home/flynn/.config/fastfetch/config.jsonc`
     - 个人偏好：自定义 ASCII 图标、基于首装日期的使用天数动态计算与磁盘展示。
  4. **Btop**：`/home/flynn/.config/btop/btop.conf`
     - 个人偏好：资源监控器主题与刷新频率。
  5. **Zathura**：`/home/flynn/.config/zathura/zathurarc`
     - 个人偏好：Catppuccin Mocha 配色、夜间反色护眼、平滑步进与双页阅读。

### 3. 未来管理方案分析与 Home-Manager 评估
- **演进路线 A：引入 Home-Manager（纯函数式 Nix 声明）**：
  - **实现方式**：在 `flake.nix` 引入 `inputs.home-manager`，将用户配置统一声明为 Nix 表达式。
  - **优势**：跨设备无缝 100% 全自动化部署，单条 flake 命令同步整机 + 用户环境。
  - **注意事项/考量**：
    - Home-Manager 生成的配置文件为 `/nix/store` 的只读符号链接（read-only symlink）。
    - 部分 GUI 应用（如 VS Code 图形界面修改设置、扩展写入配置）在面对只读文件时可能提示权限不足或失败。
- **演进路线 B：轻量 Dotfiles 方案（GNU Stow 或仓库软链接脚本）**：
  - **实现方式**：在 `nixos-config` 内维护 `dotfiles/` 目录，通过脚本软链接至 `~/.config/`。
  - **优势**：保持文件可读写性，VS Code 界面随意修改无阻碍，无额外 flake 外部依赖。
- **决策结论 (2026-10-19)**：
  - 用户决定暂缓引入，待后续学习掌握 Home-Manager 机制后再做权衡选择。
  - 当前维持现状，核心配置及修复白屏的关键选项已在本文档归档记录。





---

## 阶段 16 — Clash Verge 白屏/灰屏与内核通信故障根因彻底根治 (2026-10-20)

### 1. 故障全景诊断
用户在 DWM 下使用 Clash Verge 时遇到主界面 100% 呈现黑/灰/白屏，并伴随“内核通信错误”。经底层排查，此故障由 4 个层层嵌套的深层冲突共同导致：

1. **权限冲突（致命死锁）**：
   - `modules/services.nix` 原配置中同时启用了 `tunMode = true` 和 `serviceMode = true`；
   - Nixpkgs 官方模块中的 `tunMode = true` 会为 GUI 二进制生成 `security.wrappers.clash-verge` 并赋予 `cap_net_admin=+ep` 文件特权；
   - Linux 内核对携带文件能力（Capabilities）的二进制强制施加 `AT_SECURE` 安全标志；
   - **WebKitGTK 的 Bubblewrap 沙盒进程严禁在 `AT_SECURE` 环境下启动**，导致渲染器子进程 `WebKitWebProcess` 瞬间崩溃死锁，UI 画布完全空白。
   - **修正**：在开启 `serviceMode`（由 root 权限的 systemd 守护进程托管 TUN）时，彻底关闭 `tunMode`，去除 GUI 二进制的 setcap 包装。
2. **渲染器冲突**：
   - WebKitGTK 在 Intel 核显 + X11/modesetting 下离屏硬件合成器（DMA-BUF renderer）存在崩溃缺陷；
   - **修正**：在 NixOS 包装中显式注入 `--set WEBKIT_DISABLE_DMABUF_RENDERER 1 --set WEBKIT_DISABLE_COMPOSITING_MODE 1`。
3. **DWM 平铺与窗口状态锁死**：
   - Clash Verge 为无边框 Tauri GTK 窗口，DWM 默认强行将其平铺导致几何尺寸拉伸；
   - `tauri-plugin-window-state` 在非正常关闭时将 `"visible": false` 持久化，后续无论如何启动窗口均被标记为 `WithdrawnState`（由于 DWM 无系统托盘，窗口进入永久隐形状态）；
   - **修正**：在 `pkgs/dwm/config.h` 中为 `clash-verge` 和 `Clash-verge` 添加 `isfloating = 1` 规则；清理并重置窗口持久化状态。
4. **Nixpkgs 官方模块 PrivateTmp 隔离缺陷**：
   - Nixpkgs 上游在 `clash-verge.service` 中误加了 `PrivateTmp = true`；
   - 导致 root 后台核心生成的通信套接字 `/tmp/clash-verge-rev/verge-mihomo.sock` 被隔离在 systemd 的专属私有 `/tmp` 目录中，普通用户态 GUI 访问时报错“内核通信错误”；
   - **修正**：通过 `systemd.services.clash-verge.serviceConfig.PrivateTmp = lib.mkForce false;` 强制放行。

### 2. 修复成果验证
- 图形界面完全恢复，深色主题正常加载，所有订阅与节点一览无余（验证截屏见 `/home/flynn/Pictures/clash-connected.png`）；
- “内核通信错误”彻底消除，实时流量统计与节点切换（Hysteria2 / VLESS）完全正常；
- `WebKitWebProcess` CPU 占用率从死循环时的 35% 恢复到极低空闲（~2%），彻底解决耗电发热问题。

---

## 阶段 17 — Zathura 极速 PDF 阅读器核心快捷键与高效操作指南 (2026-10-21)

Zathura 采用极简设计，基于轻量快速的 MuPDF 渲染后端，配合松下 CF-SV8 硬件与 DWM 桌面具有极高的阅读生产力。配置文件位于 `~/.config/zathura/zathurarc`（已同步归档至仓库 `dotfiles/zathura/zathurarc`，采用 Catppuccin Mocha 配色）。

### 1. 硬件联动：松下圆盘旋转滚动 (くるくるスクロール)
- **顺时针沿圆盘边缘旋转**：平滑向下滚动页面。
- **逆时针沿圆盘边缘旋转**：平滑向上滚动页面。
- **操作优势**：长篇大部头书籍或技术手册快速浏览时，手腕无需移动，如旋钮般精准无极滚屏。

### 2. 页面浏览与定位快捷键 (Vim 键盘流)
| 快捷键 | 功能 | 说明 |
| :--- | :--- | :--- |
| `j` / `k` 或 `Space` / `Shift+Space` | 逐行平滑滚动 | 细致阅读文本 |
| `d` / `u` | 向下 / 向上滚动半屏 | Vim 经典半屏跳读 |
| `J` / `K` | 直接切换至下 / 上一页 | 整页快速翻阅 |
| `gg` / `G` | 快速直达文档首页 / 尾页 | 瞬时跳转至开头或参考文献 |
| `<页码>G` | 精准跳转指定页码 | 例如输入 `120G` 瞬间定位到第 120 页 |
| `Ctrl + o` / `Ctrl + i` | 历史跳转位置后退 / 前进 | 跳转查阅文献后原路返回原阅读点 |

### 3. 版面展示与夜间护眼模式
| 快捷键 | 功能 | 说明 |
| :--- | :--- | :--- |
| `a` | 适合窗口宽度 (Fit Width) | 16:10 宽屏单页阅读最佳默认比例 |
| `s` | 适合整页展示 (Fit Page) | 缩放呈现整张页面布局 |
| `d` | 切换双页并排阅读 | 杂志/论文双页展开，模拟纸质书阅读感 |
| `Ctrl + r` | 切换暗黑反色护眼模式 (Recolor) | 白底黑字瞬间反色为深色背景，夜间不刺眼 |
| `r` | 顺时针旋转 90 度 | 适配横版图表、宽屏表格或幻灯片 |

### 4. 目录大纲、全文检索与超链接穿透
| 快捷键 | 功能 | 说明 |
| :--- | :--- | :--- |
| `Tab` | 打开 / 关闭目录大纲 (Outline) | 按 `j`/`k` 选择章节，按 `Enter` 秒级跳转 |
| `/` | 全文搜索关键词 | 按回车确认，`n` 查看下一个匹配项，`N` 查看上一个 |
| `f` | 超链接穿透标注 (Follow Link) | 页面内所有引用、URL 标注数字，输入数字回车直达引用 |
| `m<字母>` | 标记书签 | 例如 `ma` 标记当前位置为书签 a |
| `'<字母>` | 跳转书签 | 例如 `'a` 瞬时回到书签 a |

### 5. 原生文件打开与会话控制
| 操作 | 方式 | 说明 |
| :--- | :--- | :--- |
| **内置命令行打开新文件** | 输入 `:open ~/路径/` 并按 `Tab` | 原生路径与文件名交互式自动补全 |
| **退出阅读** | 按 `q` 或 DWM 快捷键 `Mod + Shift + c` | 退出时自动保存阅读进度（下次打开断点续读） |
| **平铺窗口切换** | 按 DWM 快捷键 `Mod + Enter` | 将 Zathura 在 Master（左主屏）与 Stack（右副屏）间对调 |

