# Panasonic Let's Note CF-SV8 NixOS 配置仓库

本仓库声明式管理 Panasonic Let's Note CF-SV8 (CFSV8-2 / `CF-SV8SFKVS`) 的 NixOS 系统配置与 X11 + DWM 桌面环境。

---

## 5 分钟阅读导览

如果你第一次接手或修改本仓库，请按以下顺序阅读：

### 1. 先看哪几个文件？
1. **[modules/desktop-dwm.nix](modules/desktop-dwm.nix) 与 [pkgs/dwm/config.h](pkgs/dwm/config.h)**：
   - 负责 DWM 窗口管理器、快捷键、字体字号 (11pt)、144 DPI (1.5x 缩放)、壁纸自包含加载、锁屏 (`slock`) 与终端半透明 (`picom`)。
2. **[modules/power.nix](modules/power.nix)**：
   - 负责功耗释放与电源调度。预置了 **方案 A（原厂 10W 冷凉静音）** 与 **方案 B（20W 满血编译性能）**，通过第 69 行一个布尔值即可无痛秒切。
3. **[modules/input.nix](modules/input.nix)**：
   - 负责标准美式 US 键盘与松下经典圆形触控板驱动（`xf86-input-synaptics`），包含圆盘边缘旋转滚动（くるくるスクロール）核心参数。
4. **[modules/services.nix](modules/services.nix) 与 [modules/base.nix](modules/base.nix)**：
   - 负责网络、音频、PCManFM 文件管理、Zathura PDF 查看器、Git 以及按项目轻量加载环境的 `direnv`。

### 2. 最容易改错的 3 个地方（避坑指南）
1. **修改 DWM / st 源码后忘记 rebuild 或误加进 packages**：
   - `dwm` 与 `st` 是通过 NixOS 模块内部的 `.override` 直接使用源码编译并注入会话的。**绝对不要**把 `dwm` 写入 `environment.systemPackages`，否则定制的 `config.h` 会被官方默认二进制覆盖而失效。修改 `pkgs/*/config.h` 后，必须执行 `sudo nixos-rebuild switch --flake ~/nixos-config#sv8` 重新编译生效。
2. **新增文件未执行 `git add`**：
   - Nix Flake 具有极高的严谨性，仅能感知被 Git 跟踪的文件。若在仓库中新增了模块、补丁或图片，**必须先运行 `git add <新文件>`**，否则 rebuild 时会直接报错找不到该文件。
3. **触控板驱动冲突**：
   - 松下独有的圆盘边缘顺畅滚动完全依赖 `xf86-input-synaptics`。`services.libinput.enable` **必须严格保持为 `false`**。若不慎开启了 libinput，两者会抢占触摸板导致圆周旋转滚动完全失效。

---

## 目录结构

```
~/nixos-config
├── flake.nix / flake.lock            # Flake 入口与依赖锁文件
├── README.md                          # 本说明文档、改配置速查表、回滚指南、5分钟导览
├── CHECKLIST.md                       # 各阶段任务执行活副本（全项已验证）
├── NOTES.md                           # 硬件全功能对照表、实测数据、决策记录与原理解析
├── wallpapers/                        # 桌面壁纸资源目录（仓库自包含，随构建打包进系统）
├── legacy/                            # 迁移前原厂历史配置备份 (/etc/nixos)
├── hosts/
│   └── sv8/
│       ├── default.nix                # 主机模块入口、主机名与系统状态版本
│       └── hardware-configuration.nix # 硬件扫描生成的分区与内核模块配置
├── modules/
│   ├── base.nix                       # Nix 设置、引导上限、时区 Locale、用户、基础工具、direnv
│   ├── hardware-sv8.nix               # CPU 微码、非自由固件、panasonic_laptop、ZRAM、fstrim
│   ├── graphics.nix                   # Intel UHD 620 核显、VAAPI 硬解、modesetting、autorandr
│   ├── input.nix                      # 美式 US 键盘布局、松下圆盘触摸板 (synaptics くるくるスクロール)
│   ├── power.nix                      # 睡眠模式、TLP 省电策略、throttled 功耗双方案 (A/B 切换)
│   ├── desktop-dwm.nix                # DWM 窗口管理器、DPI 缩放、壁纸、picom 半透明、slock 锁屏
│   ├── fonts-ime.nix                  # 中日韩全套字体（Noto CJK）、Fontconfig 回退优先级（免输入法）
│   └── services.nix                   # NetworkManager、蓝牙、PipeWire 音频、PCManFM、Zathura、Clash
└── pkgs/                              # 本地自定义包与源码配置树
    ├── dwm/config.h                   # DWM 核心按键绑定与工作区 (1~6)
    ├── st/config.h & patches/         # st 终端回滚/宽字形/Ctrl+Click 补丁、竖线光标、字号配置
    ├── dmenu/config.h                 # dmenu 配色与字体
    └── slstatus/config.h              # 状态栏监控项：CPU/RAM/WIFI(✓/✗)/BAT/短时钟
```

---

## 改配置速查表

| 想修改的内容 | 对应文件路径 | 所在小节或参数 |
| :--- | :--- | :--- |
| **功耗模式 (方案 A 冷凉 vs 方案 B 满血)** | `modules/power.nix` | §3. `services.throttled.enable` (`true`/`false`) |
| **开机引导项保留代数** | `modules/base.nix` | 顶部 `let bootLimit = 3;` |
| **用户与 sudo 权限 / 用户组** | `modules/base.nix` | §4. 用户与权限 (`users.users.flynn`) |
| **系统预装 CLI 工具 / 开发包** | `modules/base.nix` | §5. 基础系统工具 (`systemPackages`) |
| **图形文件管理 / PDF / 日常软件** | `modules/services.nix` | §4. 存储、桌面支持与日常应用 |
| **键盘映射布局 (标准美式 US)** | `modules/input.nix` | §1. 键盘布局 (`xkb.layout`) |
| **圆形滚动灵敏度 / 触发方式** | `modules/input.nix` | §2. 触摸板设置 (`CircScrollDelta = "0.2"`) |
| **合盖睡眠与电源键行为** | `modules/power.nix` | §1. 睡眠模式与合盖锁屏 (`services.logind`) |
| **屏幕缩放比例 (全局 DPI)** | `modules/desktop-dwm.nix` | 顶部 `let targetDpi = 144;` (1.5x) |
| **桌面壁纸图片** | `wallpapers/` 目录 | 替换图片或修改 `modules/desktop-dwm.nix` 的 `wallpaperPath` |
| **DWM 快捷键、窗口排版** | `pkgs/dwm/config.h` | `keys[]` 数组定义 |
| **终端模拟器 (st) 字体/字号/光标** | `pkgs/st/config.h` | `font` 与 `cursorshape` (6 为竖线) |
| **应用菜单 (dmenu) 配色与字体** | `pkgs/dmenu/config.h` | `colors[]` 与 `font` |
| **状态栏 (slstatus) 监控信息** | `pkgs/slstatus/config.h` | `args[]` 数组 |
| **字体安装与 CJK 回退优先级** | `modules/fonts-ime.nix` | §1. 字体包与 Fontconfig 默认值 |

---

## 功耗方案快速切换指南 (方案 A vs 方案 B)

本机针对松下轻薄镁合金特性与日常重负载编译需求，预设了两套成熟方案：

- **方案 A（原厂 10W 冷凉静音，当前生效）**：持续功耗 10W，CPU 全核 1.6~1.7 GHz，外壳低于 48°C，超长续航，适合不插电移动办公或放膝盖上使用。
- **方案 B（20W 满血编译性能）**：持续功耗 20W，CPU 全核 2.4~3.0GHz+，编译耗时减半，适合插电桌面写代码与编译。

### 秒级切换方法
1. **即时临时切回方案 A（不重启、不 rebuild）**：
   ```bash
   sudo systemctl stop throttled
   ```
2. **永久切换**：
   打开 [modules/power.nix](modules/power.nix)，仅需修改第 69 行：
   - 切换为方案 A：`services.throttled.enable = false;`
   - 切换为方案 B：`services.throttled.enable = true;`
   然后运行 `sudo nixos-rebuild switch --flake ~/nixos-config#sv8` 即可。

---

## DWM 常用快捷键对照表

| 快捷键 | 功能 | 说明 |
| :--- | :--- | :--- |
| `Super + Shift + Enter` | 打开终端 | 启动半透明定制版 `st` 终端 |
| `Super + p` | 打开应用启动器 | 唤起 `dmenu` 搜索并启动软件 |
| `Super + Shift + c` | 关闭当前窗口 | 类似常规 Alt+F4 |
| `Super + j / k` | 切换窗口焦点 | 在平铺窗口之间按序切换 |
| `Super + h / l` | 调整主窗口分屏宽度 | 缩窄 / 放大左侧主区域比例 |
| `Super + Enter` | 窗口提升至主分屏 | 将当前聚焦窗口切换为主窗口 |
| `Super + t / f / m` | 切换排版模式 | 平铺 (Tile) / 浮动 (Floating) / 单窗口全屏 (Monocle) |
| `Super + Space` | 快速切回上一模式 | 快速在平铺与浮动间切换 |
| `Super + 1~6` | 切换工作区 (Tag) | 切换到指定虚拟桌面 (1~6) |
| `Super + Shift + 1~6` | 发送窗口至工作区 | 将当前聚焦窗口移入指定桌面 (1~6) |
| `Super + Shift + l` | 手动锁屏 | 立即调用 `slock` 黑屏锁屏，盲打输入用户密码回车解锁 |
| `Print` (Fn + Print) | 区域截图 | 选区截图并自动拷入系统剪贴板 |
| `Fn + F1 / F2` | 屏幕亮度减 / 增 | 联动 `brightnessctl`，步进 5%，平滑无频闪 |
| `Fn + F4 / F5 / F6` | 音量静音 / 减 / 增 | 联动 PipeWire (`wpctl`)，无弹窗卡顿 |
| `Super + Shift + q` | 安全退出 DWM | 返回 tty 控制台 |

---

## 日常命令（由用户手动在终端执行）

> **红线规则**：本系统的所有构建、测试与切换操作，均由用户手动执行，Agent 绝不代劳。

### 1. 临时测试新配置（推荐优先使用，不改写启动项，重启自动还原）
```bash
sudo nixos-rebuild test --flake ~/nixos-config#sv8
```

### 2. 正式应用并写入开机启动项
```bash
sudo nixos-rebuild switch --flake ~/nixos-config#sv8
```

### 3. 语法与静态检查（只评估不构建）
```bash
nix flake check ~/nixos-config --no-build
```

### 4. 磁盘空间清理（手动 GC）
系统已配置每周自动清理 7 天前旧代。若磁盘吃紧需立即清理：
```bash
# 清理旧代数生成文件并释放磁盘空间
sudo nix-collect-garbage --delete-older-than 7d
sudo nix-store --optimise
```

### 5. 故障回滚指南
- **临时测试故障**：若运行 `test` 后出现异常，直接执行 `sudo reboot`，系统会自动以之前的稳定代数启动。
- **开机启动故障**：在开机出现 systemd-boot 菜单时，使用上下方向键选择上一代稳定内核与配置即可进入系统。
- **命令行回滚**：
  ```bash
  sudo nixos-rebuild switch --rollback
  ```

---

## 新机或系统重装时如何恢复

若需要将本配置恢复到新安装的 SV8 或重装的 NixOS 系统上：

1. **克隆配置仓库**：
   ```bash
   git clone <本仓库地址> ~/nixos-config
   ```
2. **确认硬件配置差异**：
   新机安装时若磁盘 UUID 变化，运行 `nixos-generate-config --dir /tmp/hardware`，比对并替换 `hosts/sv8/hardware-configuration.nix` 中的文件系统 UUID。
3. **一键构建并切换**：
   ```bash
   sudo nixos-rebuild switch --flake ~/nixos-config#sv8
   ```
4. **重启系统**：
   重启后 tty1 自动登录并启动 DWM 桌面，所有触摸板圆形滚动、快捷键与功耗策略完整复原。

---

## 已知事项与硬件特性 (CF-SV8)
1. **CPU**：Intel Core i7-8665U (Whiskey Lake, 4C/8T)，当前开启方案 A (10W 冷凉静音超长续航)。
2. **内存**：16GB LPDDR3 (板载)，已配置 ZRAM 50% 动态压缩交换空间防 OOM。
3. **硬盘**：256GB SATA SSD (`sda`)，已启用系统级 `fstrim.weekly`。
4. **键盘**：采用标准美式 US 键盘布局（`layout = "us"`），完全移除 Fcitx5，保留全套 CJK 字体用于清晰阅读。
5. **睡眠**：固件原生支持 S3 `deep` 睡眠与 `s2idle`，合盖与电源键唤起挂起，开盖即唤醒。
6. **触摸板**：搭载松下经典圆形触摸板，已通过 `xf86-input-synaptics` 驱动原生激活经典圆盘边缘旋转滚动（くるくるスクロール，步进设置为 `0.2`）。
7. **指纹与无线滑块**：本机硬件未配备指纹模块；侧面无线滑块在 Linux 下仅物理断开蓝牙，Wi-Fi 统一由 NetworkManager / rfkill 软件管理。
