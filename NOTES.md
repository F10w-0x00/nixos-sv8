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
- **序列号**：`9JKSC52065`
- **BIOS 版本**：`V2.00L12` (发布日期：2019-06-27)
- **固件类型**：UEFI 2.70 (AMI)

### 6. 历史配置备份
- 原 `/etc/nixos/configuration.nix` 与 `hardware-configuration.nix` 已备份至 `legacy/` 目录。

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
  - `pkgs/dwm/config.h`：使用 `Mod4` (Super/Win) 键；绑定音量、亮度、锁屏及截图快捷键；顶栏字号 11。
  - `pkgs/st/config.h` & `pkgs/st/patches/`：打入官方三项回滚补丁（`st-scrollback` + `st-scrollback-mouse` + `altscreen`），支持鼠标滚轮平滑翻页与 Shift+PageUp/Down，字号 pixelsize=20。
  - `pkgs/dmenu/config.h`：Catppuccin 深色配色，字号 11。
  - `pkgs/slstatus/config.h`：纯净显示 `[BAT %s%%]`（去除多余状态符号）、CPU、RAM、Wi-Fi、时钟。
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
  - `Synaptics Circular Scrolling Distance (353) = 0.1`
- 实机体验：圆盘画圈滚动平滑自然，轻触左键、双指右键灵敏有效。
