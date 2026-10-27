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
- **多媒体按键支持**：
  - 亮度与音频：通过标准 AT PS/2 scancode 触发标准 XF86 键码，直接联动 `intel_backlight` 与 PipeWire (`wpctl`)。
  - 快捷锁屏与截图：DWM 绑定 `slock` 与 `maim + xclip`。全量按键速查表详见 `docs/SKILL.md`。

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

## 阶段 5 附录 — 固化原厂 10W 能效与低功耗调校规程

经实机长周期测试与离电使用验证，系统已彻底固化**方案 A（原厂 10W 冷凉静音超长续航策略）**，并清除了所有与 `throttled` 切换相关的冗余代码：

### 1. 固化方案 A 的技术收益
- **温度与噪音表现**：满载温度稳定在 48~50°C，外壳保持极度温凉，风扇微风静音。
- **离电续航表现**：整机空闲待机功耗实测低至 **~5.15W**，电池驻留时间显著延长至 7~9 小时。
- **系统纯净度**：彻底移除常驻的 MSR 寄存器高频周期性覆写守护进程（`throttled`），100% 依赖 Linux 原生 TLP 与硬件固件调度，零后台开销、零额外故障面。

---

## 阶段 8 — 松下 CF-SV8 硬件功能完整对照表

| 硬件功能项 | 状态 | 落地驱动 / 配置方案 | 详细实测说明与调优备注 |
| :--- | :---: | :--- | :--- |
| **圆形滚动 (くるくるスクロール)** | **正常** | `xf86-input-synaptics` (`modules/input.nix`) | 实测圆盘边缘顺时针/逆时针顺畅滚动；`CircScrollDelta=0.2` 手感自然稳定 |
| **触摸板点按 / 平移** | **正常** | `xf86-input-synaptics` (`modules/input.nix`) | 单指左键、双指右键、三指中键；双指平移滚动兼容传统操作 |
| **亮度按键** | **正常** | PS/2 scancode + `brightnessctl` | 步进 5%，直接调控 `intel_backlight`，平滑无频闪（按键详见 `docs/SKILL.md`） |
| **音量按键** | **正常** | PS/2 scancode + PipeWire (`wpctl`) | 一键静音、音量加减、麦克风静音，无弹窗卡顿（按键详见 `docs/SKILL.md`） |
| **功能按键 (锁屏/截图)** | **正常** | DWM 绑定 `slock` / `maim` + `xclip` | 黑屏锁屏与单键截图秒进系统剪贴板（按键详见 `docs/SKILL.md`） |
| **无线滑块物理开关** | **部分** | DSDT MAT0028 只读识别 | 拨动滑块可物理切断蓝牙；Linux 暂无 MAT0028 驱动，依红线 4 不侵入写 EC，软件通过 NM/rfkill 统一管理 |
| **睡眠模式 (Suspend)** | **正常** | ACPI 原生支持 `[s2idle] deep` | `services.logind` 合盖挂起，`xss-lock` 联动锁屏；功耗极低 |
| **系统休眠 (Hibernate)** | **已跳过** | 用户阶段 0 决策跳过 | 阶段 0 明确无需磁盘 swap 挂起，纯使用 S3 deep 睡眠，节约 SSD 磨损 |
| **多途径系统唤醒** | **正常** | UEFI 2.70 AMI 固件原生支持 | 开盖 (`LID0`)、轻按电源键 (`PWRF`)、外接鼠标 (`XHC`) 均可唤醒，无需高风险 `acpi_call` |
| **屏幕闪屏** | **无闪屏** | Intel UHD 620 (`i915` + modesetting) | 多小时重负载、调亮度、编译未发生任何闪屏，内核日志健康 |
| **功耗与编译性能** | **正常** | 固化 10W 原厂能效策略 (`modules/power.nix`) | 10W 极度冷凉静音超长续航，整机待机仅 ~5.15W |
| **放电功耗与续航** | **正常** | TLP 能效调度 + Intel C-states | CPU 空闲封装仅 3.02W，C10 深度驻留，整机待机仅 ~7.5W |
| **RGB 高清摄像头** | **正常** | 内核 UVC 驱动 (`/dev/video0,1`) | Bison Electronics 720p HD Webcam 出流正常 |
| **红外人脸相机 (IR)** | **就绪** | 内核 UVC 驱动 (`/dev/video2,3`) | 红外硬件完备可用，支持 Linux Howdy 人脸解锁方案 |
| **内置麦克风与扬声器** | **正常** | PipeWire 1.6.6 + WirePlumber (`snd_hda_intel`) | 立体声输出清晰，内置麦克风采集良好，无爆音 |
| **SD 读卡器** | **正常** | 内核 `sdhci-pci` (O2 Micro OZ777 `1217:8520`) | PCIe 控制器加载正常，支持大容量 SD 卡即插即读 |
| **外接显示输出 (HDMI)** | **正常** | Intel UHD 620 + `autorandr` (`modules/graphics.nix`) | 支持 HDMI 外接高分屏与多屏自动重排 |
| **Type-C / 雷电 3 (TB3)** | **正常** | `thunderbolt` + UCSI PD 驱动 | 支持 65W PD 诱骗快充与雷电高速外设数据传输 |
| **指纹识别模块** | **不可用** | 硬件未配备 | 原厂选配项，本机未搭载指纹传感器硬件（`lsusb`/`lspci` 确认不存在） |
| **内置 DVD 刻录光驱** | **正常** | `HL-DT-ST DVDRAM GUD0N` (`/dev/sr0`) | 9.5mm 超薄 SATA 光驱，已配置免提权刻录工具集 (`dvdplusrwtools` / `cdrkit` / `xorriso`) 与防睡眠指南 (`docs/DVD-BURNING.md`)；2026-10-22 实测成功刻录《比宇宙更远的地方》DVD+R，电磁开仓与写入完全正常 |
| **WWAN 4G 蜂窝网络** | **正常** | Sierra Wireless MC7455 (`qcserial` + `cdc_mbim`) | 驱动加载完毕，NetworkManager 识别为 `enabled` |

---

## 阶段 9 — 用户级配置 (~/.config) 盘点与 Home-Manager 演进预留 (2026-10-19)

### 1. 系统级配置 vs 用户级配置现状边界
- **系统级环境（100% 声明式且可复现）**：
  - DWM 窗口管理器、Alacritty 终端、slstatus 状态栏、dmenu 启动器：源码与配置已嵌入仓库并通过 Nix 声明注入，不产生或依赖 `~/.config` 文件。
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
     - 个人偏好：`size = 13.0`、JetBrainsMono Nerd Font、`opacity = 1.0`、无边框窗口模式 (Windowed)。
  3. **Fastfetch**：`/home/flynn/.config/fastfetch/config.jsonc`
     - 个人偏好：自定义 ASCII 图标、官方原生 `uptime` 运行时间展示、底部 Catppuccin Mocha 对称彩虹色谱圆环（Chris Titus 风格定制）。
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

## 阶段 17 — Zathura 极速 PDF 阅读器集成与配置 (2026-10-21)

Zathura 采用极简设计，基于轻量快速的 MuPDF 渲染后端，配合松下 CF-SV8 硬件与 DWM 桌面具有极高的阅读生产力。
- **配置文件**：`~/.config/zathura/zathurarc`（已同步归档至仓库 `dotfiles/zathura/zathurarc`，采用 Catppuccin Mocha 配色与夜间护眼模式）。
- **硬件联动**：完美支持松下圆盘边缘顺时针/逆时针旋转滚动（くるくるスクロール）。
- **全套 Vim 快捷键与操作技巧**：已完全解耦并整理至专用技能文档 `docs/SKILL.md`。

---

## 阶段 10：拆分 sv8.nix 与配置解耦 (阶段记录)

### 1. 待办事项归档 (Review R8 & R9)
- **[待办 R8] 电池与深入节能调优备选项**：
  - SATA 链路电源管理与运行时 PM (Runtime PM) 显式配置。
  - 拔掉电源自动降低屏幕背光亮度规则。
  - 空闲状态超时息屏与超时自动挂起联动。
  - Firefox 媒体配置：禁用高耗能 AV1 软解解码，强制使用 VAAPI 硬件解码能效更优的编解码器。
  - 蓝牙电源启动默认项优化：评估是否调整 `hardware.bluetooth.powerOnBoot = false`。
  *(注：当前方案 A 基础功耗约 5.15W，上述措施作为后续追求极限续航时的可选优化方案)*
- **[待办 R9] 公开仓库素材版权核查**：
  - 仓库已推送到 GitHub 公开仓库，后续对 `wallpapers/` 目录下图片进行版权审计，仅保留自有拍摄、创作或无版权/CC0 授权壁纸。

### 2. 重构前基线快照 (A6 校验基准)
- **当前系统代数**：Generation 52
- **重构前 toplevel drvPath**：
  `/nix/store/9gylnhdjjpr5bgr45wcwdlpy2bd0whbc-nixos-system-sv8-26.05.20261015.26f4107.drv`

### 3. A1 完整配置项归类对照表 (覆盖所有 .nix 与 pkgs/)

判断依据准则：**「换一台没有这些硬件的电脑，这行配置会失效、有害或没有意义吗？」**
- 是 → 归入 `hosts/sv8/sv8.nix`（或 `hosts/sv8/` 主机层）
- 否 → 归入 `modules/`（通用模块库，供多台电脑共用）

| 配置项 / 代码段 | 现有位置 | 拟定归类位置 | 归类理由与硬件依赖性说明 |
| :--- | :--- | :--- | :--- |
| `boot.kernelModules = [ "panasonic_laptop" ]` | `modules/hardware-sv8.nix` | `hosts/sv8/sv8.nix` §2 | [SV8] 松下笔记本独占 WMI/ACPI 平台驱动，在非松下电脑上加载无意义 |
| `hardware.cpu.intel.updateMicrocode` | `modules/hardware-sv8.nix` | `hosts/sv8/sv8.nix` §1 | [SV8] 针对 Intel 处理器的微码注入，换 AMD 机器会报错或失效 |
| `hardware.enableRedistributableFirmware = true` | `modules/hardware-sv8.nix` | `modules/base.nix` §1 | 通用固件包，现代笔记本 Wi-Fi/蓝牙等几乎普遍需要 |
| `zramSwap = { enable = true; ... }` | `modules/hardware-sv8.nix` | `modules/base.nix` §1 | 通用系统内存动态压缩调优，与特定机器硬件无关 |
| `services.fstrim = { enable = true; ... }` | `modules/hardware-sv8.nix` | `modules/base.nix` §1 | 通用 SSD 定期 TRIM 维护，跨机器通用的存储维护策略 |
| `hardware.graphics.extraPackages = [ intel-media-driver libvdpau-va-gl ]` | `modules/graphics.nix` | `hosts/sv8/sv8.nix` §3 | [SV8] Intel Whiskey Lake 核显 VA-API 硬件解码器，在 AMD/Nvidia 设备上不适用 |
| `services.xserver.videoDrivers = [ "modesetting" ]` | `modules/graphics.nix` | `hosts/sv8/sv8.nix` §3 | [SV8] Intel 核显推荐 modesetting，独显/AMD 平台可能选用不同驱动 |
| `boot.kernelParams = [ "i915.enable_psr=0" ]` | `modules/graphics.nix` | `hosts/sv8/sv8.nix` §3 | [SV8] 专为松下 CF-SV8 i915 面板规避闪屏的内核补丁，其他机器无需也不应写死 |
| `hardware.graphics.enable = true` | `modules/graphics.nix` | `modules/graphics.nix` | 通用图形渲染栈基础设置 |
| `services.autorandr.enable = true` | `modules/graphics.nix` | `modules/graphics.nix` | 通用外接多显示器自动适配守护工具 |
| `services.libinput.enable = false` | `modules/input.nix` | `hosts/sv8/sv8.nix` §4 | [SV8] 为让路松下 synaptics 圆盘驱动而特殊关闭；通用机型应保持 libinput 默认开启 |
| `services.xserver.synaptics = { ... }` (圆盘旋转滚动) | `modules/input.nix` | `hosts/sv8/sv8.nix` §4 | [SV8] 松下 Let's Note 招牌圆形触控板专用驱动与参数，换其他电脑无此硬件 |
| `environment.systemPackages = [ xf86-input-synaptics xinput ]` | `modules/input.nix` | `hosts/sv8/sv8.nix` §4 | [SV8] 松下圆盘调试工具，属于本机配套支撑 |
| `services.xserver.xkb.layout = "us"`, `console.keyMap = "us"` | `modules/input.nix` | `modules/input.nix` | 个人习惯的美式键盘偏好，多电脑通用 |
| `boot.kernelParams = [ "mem_sleep_default=deep" ]` | `modules/power.nix` | `hosts/sv8/sv8.nix` §5 | [SV8] CF-SV8 固件明确支持 S3 deep，换无 S3 机器强制 deep 可能导致无法唤醒 |
| `services.upower.enable = true` | `modules/power.nix` | `modules/power.nix` | 通用电源电量事件监控守护服务 |
| `services.logind.settings.Login` (合盖/电源键) | `modules/power.nix` | `modules/power.nix` | 个人电源按键与盒盖交互偏好，多电脑通用 |
| `services.tlp` 调频、EPP、ASPM、Wi-Fi/声卡节能 | `modules/power.nix` | `modules/power.nix` | 个人续航与能效策略，多电脑通用 |
| `services.tlp.settings.USB_AUTOSUSPEND = 0` | `modules/power.nix` | `modules/power.nix` | 彻底关闭 USB 自动挂起，杜绝 2.4G 无线鼠标接收器延迟与间歇卡死 |
| `services.xserver.dpi = 144` | `modules/desktop-dwm.nix` | `hosts/sv8/sv8.nix` §3 | [SV8] 针对 CF-SV8 12.1寸 1920x1200 屏幕定制的 1.5x 视觉 DPI；通用模块读取该选项（默认回退 96） |
| `customSlstatus` 电池名称 `"BAT1"` | `pkgs/slstatus/config.h` | `hosts/sv8/sv8.nix` §6 | [SV8] 松下电池节点为 BAT1；通用模块定义 `my.batteryName` 选项（默认 "BAT0"），由 `replaceVars` 动态注入模板 |
| `wallpaperPath` (Kurisu.png/wallpaper.png) | `modules/desktop-dwm.nix` | `modules/desktop-dwm.nix` | 个人桌面壁纸偏好，随仓库自包含分发 |
| `startx`, DWM, Alacritty, dmenu, picom, slock 等桌面组件 | `modules/desktop-dwm.nix` | `modules/desktop-dwm.nix` | 通用平铺桌面环境，跨机器通用 |
| `fonts` 与 `fonts.fontconfig.defaultFonts` | `modules/fonts-ime.nix` | `modules/fonts-ime.nix` | 个人 CJK 阅读与编程等宽字体偏好，跨机器通用 |
| 基础服务 (NetworkManager, Bluetooth, PipeWire, fwupd, udisks2, portal) | `modules/services.nix` | `modules/services.nix` | 现代桌面基础环境，跨机器通用 |
| 应用软件 (Firefox, PCManFM, Zathura, LocalSend 等) | `modules/services.nix` | `modules/services.nix` | 个人日常软件套件，跨机器通用 |
| 代理服务 (Clash Verge Rev) | `modules/services.nix` | `modules/services.nix` | 个人网络代理方案，跨机器通用（待用户确认 R3 后微调注释或模式） |
| Nix 设置、GC、boot.loader、用户 `flynn`、开发工具 | `modules/base.nix` | `modules/base.nix` | 个人开发与运维环境基线，跨机器通用（待用户确认 R7 后微调系统级包） |
| `fileSystems`, `swapDevices`, `initrd` 驱动模块 | `hosts/sv8/hardware-configuration.nix` | `hosts/sv8/hardware-configuration.nix` | 主机底层硬件固有分区与驱动，属于主机层 |
| `networking.hostName`, `system.stateVersion` | `hosts/sv8/default.nix` | `hosts/sv8/default.nix` | 主机标识层固有参数 |

### 4. 任务 B：光标主题调优与延迟根治记录

- **初版体验反馈**：初版引入 `apple-cursor` (macOS 32px) 后，用户实机反馈鼠标在移动到超链接时有明显的“阻滞感/粘滞感”。
- **深层根因溯源**：
  1. `apple-cursor` 单个 `pointer` 文件高达 173.5 KB，内置 10 种分辨率多层位图，X11 每次跨越链接均触发显存位图重载，产生微卡顿；
  2. 箭头光标（左上角）与手型光标（中心食指）热点与视觉重心位移较大，视觉产生被“吸附”假象；
  3. Firefox 默认使用传统 X11 事件流，DOM hover 与光标切换串行阻塞。
- **最终演进决策 (方案 C + 异步事件流)**：
  1. `modules/appearance.nix`：切换回 Linux 原生经典低延迟 `Adwaita`（24px，来自 `adwaita-icon-theme`），位图轻量无解码负担，热点精准；
  2. `modules/services.nix`：注入 `MOZ_USE_XINPUT2 = "1";`，开启异步高精度事件流，彻底消除链接跨越事件阻塞。

| 适配层级 | 涉及配置文件 | 生效目标程序 | 验证方法与标准输出 |
| :--- | :--- | :--- | :--- |
| **X11 资源数据库 (xrdb)** | `modules/appearance.nix` §3 (`Xcursor.theme` / `Xcursor.size`) | DWM 根窗口、dmenu、slock 等原生 X11 程序 | `xrdb -query \| grep -i xcursor` 显示 `Xcursor.theme: Adwaita` / `size: 24` |
| **全局环境变量 (XCURSOR_*)** | `modules/appearance.nix` §2 (`XCURSOR_THEME` / `XCURSOR_SIZE`) | Alacritty、VS Code (Electron)、Qt | `echo $XCURSOR_THEME $XCURSOR_SIZE` 输出 `Adwaita 24` |
| **GTK 3/4 设置 (settings.ini)** | `/etc/xdg/gtk-3.0/settings.ini` 与 `gtk-4.0` | Firefox、PCManFM、Clash Verge (WebKitGTK) | `gtk-cursor-theme-name=Adwaita`、`gtk-cursor-theme-size=24` |

### 5. eMudhra (emSign) 中间 CA 私钥泄露事故处置 (2026-10)

- **漏洞原理**：印度 CA 机构 eMudhra 在 2025 年 4 月密钥生成过程中发生脚本错误，生成的 8 个中间 CA 证书私钥严重缺乏熵（甚至直接等同于单字节极小整数如 `4`），攻击者可瞬间逆向私钥，从而能够任意为任意域名签署受信任的伪造 TLS 证书。
- **影响范围**：由于其挂载并交叉签署于全局根证书（如 `emSign ECC Root CA - G3`），任何直接或间接信任该根证书的客户端若未开启 Certificate Transparency 强校验，都会遭受全流量中间人攻击（MITM）。
- **实测验证**：
  - 测试命令：`curl https://dv-g3b-emudhra.we-have-a-problem.com/`
  - 修复前响应：`HTTP 200 OK`，OpenSSL 验证通过（`verify result: 0`），证明系统此前信任了受损根链！
- **NixOS 缓解方案**：
  - 在 `modules/base.nix` 中配置 `security.pki.caCertificateBlacklist`：
    ```nix
    security.pki.caCertificateBlacklist = [
      "emSign ECC Root CA - C3"
      "emSign ECC Root CA - G3"
      "emSign Root CA - C1"
      "emSign Root CA - G1"
    ];
    ```
  - 重建系统后，NixOS 会在生成 `/etc/ssl/certs/ca-bundle.crt` 时自动剥离这 4 个根证书，后续 `curl` 访问受损证书将直接报错拒绝连接（code 60: certificate rejected）。

### 6. 默认终端迁移 (st -> Alacritty) 与 USB 节能修复记录

- **终端迁移**：
  - `pkgs/dwm/config.h` 将 `termcmd` 改为 `"alacritty"`；
  - `modules/desktop-dwm.nix` 移除 `customSt` 构建与 5 项补丁；
  - `modules/services.nix` 注入 `environment.sessionVariables.TERMINAL = "alacritty";`；
  - `dotfiles/alacritty/alacritty.toml` 与用户配置设置 `startup_mode = "Windowed"`，解决此前覆盖 DWM 顶部状态栏问题。
- **USB 节能深度溯源与根治**：
  - **根本诱因实测**：读取 sysfs 发现并非仅接收器自身休眠，而是 Intel Cannon Point-LP USB 3.1 xHCI 控制器（PCI `0000:00:14.0`）与根集线器 `usb1` 被 TLP PCIe ASPM 强制置为 `power/control = auto`。无操作 2 秒后整个 USB 总线主控进入 D3 挂起，再次晃动鼠标时控制器需重新唤醒，导致鼠标移动时严重周期性停滞（每次卡 1~2 秒）。
  - **三重固化方案 (`modules/power.nix`)**：
    1. 内核级：`boot.kernelParams = [ "usbcore.autosuspend=-1" ];` 全局禁用 USB 自动休眠；
    2. TLP 策略级：加入 `RUNTIME_PM_DENYLIST = "00:14.0";`（禁止挂起 USB 主控）与 `USB_DENYLIST = "3151:3020";`（锁定接收器）；
    3. Udev 规则级：`services.udev.extraRules` 强制保持 PCI USB 主控 (`0x0c0330`)、USB 集线器 (`09`) 与 2.4G 接收器 `power/control = on`；
    4. X11 驱动级 (`modules/input.nix`)：屏蔽 `YICHIP 2.4G Receiver Consumer Control` 误注册为第二鼠标，消除 X11 双指针事件争抢导致的间歇性挂起。
  - **实测验收 (2026-10-22)**：用户在重启 X 会话后进行连续滑动与使用实测，确认间歇性冻结/停滞故障彻底消除。
  - **精细化节能重构 (2026-10-26)**：
    - **背景**：此前证实鼠标硬件卡顿主因为电池电量耗尽（实测仅 0.9V，换新电池已彻底恢复），全局关闭 USB 休眠与锁定 xHCI 会连坐内置外设（LTE/Webcam/Bluetooth/Hubs）并阻断 CPU Package 进入深层休眠（Pkg C8/C10），导致离电待机产生约 1W 额外暗电功耗。
    - **靶向重构方案**：移除全局 `usbcore.autosuspend=-1`、TLP xHCI 黑名单与通用 Hub 锁，改为纯粹针对 2.4G 接收器硬件 ID（`3151:3020`）执行 `power/control = on` 与 TLP `USB_DENYLIST`。在确保鼠标零休眠丢帧的同时，完全释放整机低功耗待机能力。

### 7. 软件精简与彻底垃圾回收 (Steam & Piliplus)

- **移除原因**：精简非必需桌面应用，释放根分区磁盘空间。
- **配置变更**：
  - `modules/services.nix`：彻底移除 `programs.steam` 配置及其远程畅玩防火墙规则；
  - `modules/services.nix`：从 `environment.systemPackages` 中移除 `piliplus`。
- **全量 GC 方案**：
  - `sudo nix-collect-garbage -d`：删除所有旧代数系统 profile；
  - `nix-collect-garbage -d`：删除用户 profile 历史；
  - `sudo nix-store --optimise`：硬链接去重合并 store 空间。

### 8. 文本划选与复制阻滞感根治 (Picom 剔除与直通渲染)

- **故障现象**：在浏览器、终端或编辑器中拖拽划选、复制文字时，存在强烈的“粘滞阻力感 / 拖不动感”。
- **深层机理溯源**：
  1. **硬件光标 vs Damage 区域渲染时差**：普通鼠标移动由 GPU 硬件光标图层（Hardware Cursor Plane）独立直出，延迟为 0ms；而拖拽划选文本时，字符高亮框是应用内部的损伤重绘（Damage），必须通过 X11 事件管线。
  2. **Picom GLX VSync 缓冲惩罚**：此前配置启用了 `services.picom = { backend = "glx"; vSync = true; };`。每次高频划选字符，局部重绘都必须等待 60Hz 垂直同步（16.6ms），导致高亮框跟随滞后物理指针 1~2 帧（16~33ms），造成极其强烈的物理粘滞错觉。
  3. **DWM 平铺桌面的冗余开销**：DWM 窗口均为 100% 不透明，且未启用阴影与淡入淡出，Picom 实际无任何视觉特效产出，反而常态消耗约 1% CPU 并引入重绘排队。
- **固化方案 (`modules/desktop-dwm.nix`)**：
  - 显式声明 `services.picom.enable = false;`，停用桌面合成器。
  - X11 采用 Glamor 纯直通渲染，窗口内部 Damage 绘制零等待缓冲，划词高亮完全跟随手速，同时释放常驻 CPU 功耗。

### 9. 触控板偶发跳动排查与操作技能文档解耦 (2026-10-22)

- **光标偶发跳动原因排查**：
  - 分析 `Synaptics TM3136-020` 圆形触摸板硬件属性，发现该硬件控制器缺乏接触面积与手指宽度（Finger Width）上报能力（Xorg 日志明确提示 `invalid finger width range`）。
  - 因此，synaptics 驱动的常规 `PalmDetect` 算法无法精确区分大面积手掌与单指。当双手在键盘输入或手腕靠近圆形触控板边缘时，轻微拂过即会被误判为指针移动，产生偶发的“瞬移/跳动”。
  - 应对策略：使用外接 2.4G 鼠标时，手掌保持离开圆形触控板；后续若需要可在插入外接鼠标时通过 udev / xinput 脚本自动临时禁用触控板。
- **操作技能与快捷键解耦**：
  - 将原本分散记录在 `NOTES.md` 中的所有快捷键速查表（DWM 窗口管理、多媒体 Fn 键、Zathura 快捷键、触控板手势、Alacritty 终端操作）全量迁移并整合至专用技能文档 `docs/SKILL.md`（并保留 `docs/SHORTCUTS.md` 软链接）。
  - `NOTES.md` 专注于纯粹的架构演进、硬件参数基线、故障根因分析与调优档案。

### 10. DVD+R 光盘刻录首次实测验收与依赖闭环 (2026-10-22)

- **实机刻录验证**：
  - 用户使用松下 CF-SV8 内置 9.5mm 超薄刻录机（`HL-DT-ST DVDRAM GUD0N`，`/dev/sr0`）成功执行物理烧录；
  - 刻录内容：《比宇宙更远的地方》（Uchuu Yorimo Toui Basho / よりもい）S01 蓝光压制合集；
  - 核心参数：4x 写入速度（`-speed=4`）、DVD-ROM 兼容引导（`-dvd-compat`）、`systemd-inhibit` 阻塞睡眠锁；
  - 卷标命名：`Yorimoi`（符合 ISO 9660 标准 ≤ 32 字符约束）；
  - 刻录结果：双层文件系统结构生成完毕，成功写入盘片，硬件电磁弹出正常。
- **依赖遗漏与整改**：
  - 现象：`growisofs` 在执行目录实时直刻（On-the-fly mastering）时，依赖 `mkisofs` 生成 ISO9660 数据流；原系统仅安装 `dvdplusrwtools` 导致报 `mkisofs: No such file or directory`。
  - 根治：在 `hosts/sv8/sv8.nix` §8 补全 `cdrkit`（原生提供 `mkisofs` 与 `genisoimage`），实现系统级免 nix-shell 开箱即用直刻；
  - 文档完善：在 `docs/DVD-BURNING.md` 标明 Volume ID 长度上限（≤ 32 字符）与文件夹路径带空格时强制双引号规范。

### 11. 硬件级虚拟化 (KVM + Libvirt + Virt-Manager) 落地

- **需求背景**：用户需要在松下 CF-SV8 上运行 `en-us_windows_10_iot_enterprise_ltsc_2021_x64_dvd_257ad90f` 虚拟机以满足特定 Windows 业务需求。
- **架构方案 (`modules/virtualisation.nix`)**：
  - 虚拟化底层：Linux 原生 KVM + 精简裁剪版 `pkgs.qemu_kvm`（仅保留 x86_64 宿主架构支持，节约空间与下载带宽）；
  - 固件与安全：UEFI OVMF 默认固件集成，`swtpm` 虚拟 TPM 2.0 支持；
  - 驱动支持：构建软链接 `/run/current-system/sw/share/virtio-win/virtio-win.iso`，提供开箱即用的 Red Hat VirtIO 高性能虚拟化驱动（磁盘与千兆网卡）；
  - 图形交互：Virt-Manager + SPICE 协议（USB 重定向、双向剪贴板与分辨率自适应）；
  - 驱动归属解析：明确虚拟机硬件全由 QEMU 模拟与 VirtIO 驱动接管，严禁安装松下官网驱动与第三方驱动工具。完整指南固化于 `docs/VIRTUALIZATION.md`。

### 12. Docker 容器引擎与 Compose 多编排集成

- **技术实现**：
  - `virtualisation.docker.enable = true;`：启用 Docker 守护进程；
  - `autoPrune`：启用每周自动垃圾回收，防止悬空镜像与构建缓存吞噬固态硬盘空间；
  - 免 sudo 支持：主用户加入 `docker` 用户组；
  - 编排工具：集成 `pkgs.docker-compose`，支持标准 `docker compose` 与 `docker-compose` 指令。
  - 详细运维手册固化于 `docs/DOCKER.md`。

### 13. 显示平滑调优 (VSync picom) 与 Watchdog 彻底钝化

- **VSync 垂直同步消除撕裂 (`modules/desktop-dwm.nix`)**：
  - 针对网页/PDF 快速滑动时的横向画面断层（Screen Tearing），配置极简轻量级 `picom`；
  - 采用 `backend = "glx"; vSync = true;` 锁死 60Hz 垂直双缓冲，同时启用 `use-damage = true;` 与 `unredir-if-possible = true;`；
  - 彻底关闭阴影、渐变淡入淡出、透明度计算，保持 0 视觉延迟与最低功耗。
- **Watchdog 彻底钝化 (`hosts/sv8/sv8.nix`)**：
  - 内核参数加入 `nowatchdog`，关闭内核 NMI 锁检测；
  - 黑名单屏蔽 `iTCO_wdt`、`mei_wdt`、`intel_oc_wdt`，消除 CPU 周期中断唤醒，加速关机断电流程。







