# Panasonic Let's Note CF-SV8 NixOS 配置仓库

本仓库声明式管理 Panasonic Let's Note CF-SV8 (CFSV8-2 / CF-SV8SFKVS) 的 NixOS 系统配置。

---

## 目录结构

```
~/nixos-config
├── flake.nix / flake.lock            # Flake 入口与依赖锁文件
├── README.md                          # 本说明文档、改配置速查表、回滚指南
├── CHECKLIST.md                       # 各阶段任务执行活副本
├── NOTES.md                           # 硬件盘点、决策记录与实测数据
├── legacy/                            # 迁移前历史配置备份 (/etc/nixos)
├── hosts/
│   └── sv8/
│       ├── default.nix                # 主机模块入口、主机名与系统状态版本
│       └── hardware-configuration.nix # 硬件扫描生成的分区与内核模块配置
├── modules/
│   ├── base.nix                       # Nix 设置、systemd-boot、时区 Locale、用户、基础工具
│   ├── hardware-sv8.nix               # 微码、非自由固件、panasonic_laptop 驱动、ZRAM、fstrim
│   ├── graphics.nix                   # Intel UHD 620 核显、VAAPI 硬解、modesetting 驱动
│   ├── input.nix                      # JIS 日文物理键盘布局、触摸板配置
│   ├── power.nix                      # 睡眠模式、TLP 省电策略、功耗限制
│   ├── desktop-dwm.nix                # DWM 窗口管理器、桌面组件与快捷键
│   ├── fonts-ime.nix                  # 中日韩字体（Noto CJK）、Fontconfig 回退、Fcitx5 输入法
│   └── services.nix                   # NetworkManager、蓝牙、PipeWire 音频、fwupd、日常应用
└── pkgs/                              # 本地自定义包或源码补丁（DWM/st/dmenu 等）
```

---

## 改配置速查表

| 想修改的内容 | 对应文件路径 | 所在小节 |
| :--- | :--- | :--- |
| 启动菜单保留代数 | `modules/base.nix` | §2. 引导加载器 (`bootLimit`) |
| 用户与 sudo 权限 / 组 | `modules/base.nix` | §4. 用户与权限 |
| 系统预装基础 CLI 工具 | `modules/base.nix` | §5. 基础系统工具 |
| ZRAM 内存交换比例 | `modules/hardware-sv8.nix` | §3. 存储与内存优化 (`memoryPercent`) |
| 视频硬件编解码驱动 | `modules/graphics.nix` | §1. 核显驱动与视频加速 |
| 键盘映射布局 (默认 US) | `modules/input.nix` | §1. 键盘布局 (`xkb.layout`) |
| 触摸板参数与滚动行为 | `modules/input.nix` | §2. 触摸板基础设置 |
| 睡眠模式 (deep / s2idle) | `modules/power.nix` | §1. 睡眠模式基线 |
| 省电策略 (TLP) | `modules/power.nix` | §2. 电源管理骨架 |
| 屏幕缩放比例 (DPI) | `modules/desktop-dwm.nix` | §1. 显示与 DPI 设置 (`targetDpi`) |
| DWM 窗口管理器与启动项 | `modules/desktop-dwm.nix` | §2. TTY 自动登录与 §3. DWM 窗口管理器 |
| DWM 快捷键与外观定制 | `pkgs/dwm/config.h` | 键盘按键与外观规则 |
| 终端模拟器 (st) 外观与字体 | `pkgs/st/config.h` | 字体与像素大小 |
| 应用菜单 (dmenu) 外观与字体 | `pkgs/dmenu/config.h` | 菜单颜色与字体 |
| 状态栏 (slstatus) 监控项 | `pkgs/slstatus/config.h` | 状态栏显示模块 |
| 字体安装与 CJK 回退优先级 | `modules/fonts-ime.nix` | §1. 字体包与 Fontconfig 默认值（保留 CJK 阅读） |
| 蓝牙开关与默认行为 | `modules/services.nix` | §1. 网络与蓝牙 |
| 音频配置 (PipeWire) | `modules/services.nix` | §2. 音频子系统 |

---

## DWM 常用快捷键对照表

| 快捷键 | 功能 | 说明 |
| :--- | :--- | :--- |
| `Super + Shift + Enter` | 打开终端 | 启动定制版 `st` 终端 |
| `Super + p` | 打开应用启动器 | 唤起 `dmenu` 搜索并启动程序 |
| `Super + Shift + c` | 关闭当前窗口 | 类似常规 Alt+F4 |
| `Super + j / k` | 切换窗口焦点 | 在平铺窗口之间按序切换 |
| `Super + h / l` | 调整主窗口分屏宽度 | 缩窄 / 放大左侧主区域比例 |
| `Super + Enter` | 窗口提升至主分屏 | 将当前聚焦窗口切换为主窗口 |
| `Super + t / f / m` | 切换平铺 / 浮动 / 单窗口全屏模式 | 窗口排版模式快速切换 |
| `Super + Space` | 切换当前布局与上一布局 | 快速在平铺与浮动间切换 |
| `Super + 1~9` | 切换工作区 (Tag) | 切换到指定虚拟桌面 |
| `Super + Shift + 1~9` | 发送窗口至工作区 (Tag) | 将当前聚焦窗口移入指定桌面 |
| `Super + Shift + l` | 手动锁屏 | 立即调用 `slock` 锁屏 |
| `Super + Shift + s` / `Print` | 区域截图 | 选区截图，自动拷入剪贴板并存入 `~/Pictures/`，带系统通知 |
| `Super + Print` | 全屏截图 | 截取全屏，自动拷入剪贴板并存入 `~/Pictures/`，带系统通知 |
| `Fn + F1 / F2` | 屏幕亮度减 / 增 | 联动 `brightnessctl` |
| `Fn + F4 / F5 / F6` | 音量静音 / 减 / 增 | 联动 PipeWire (`wpctl`) |
| `Super + Shift + q` | 安全退出 DWM | 返回 tty 控制台 |

---

## 日常命令（由用户手动在终端执行）

> **红线规则**：本系统的所有构建、测试与切换操作，均由用户手动执行，Agent 不代劳。

### 1. 临时测试新配置（推荐优先使用，不改写启动项，重启自动还原）
```bash
sudo nixos-rebuild test --flake ~/nixos-config#sv8
```

### 2. 正式应用并写入开机启动项
```bash
sudo nixos-rebuild switch --flake ~/nixos-config#sv8
```

### 3. 仅构建检查（不激活）
```bash
nix build ~/nixos-config#nixosConfigurations.sv8.config.system.build.toplevel
```

### 4. 语法与静态检查（只评估不构建）
```bash
nix flake check ~/nixos-config --no-build
```

### 5. 故障回滚指南
- **临时测试故障**：若运行 `test` 后出现异常，直接执行 `sudo reboot`，系统会自动以之前的稳定代数启动。
- **开机启动故障**：在开机出现 systemd-boot 菜单时，使用上下方向键选择上一代稳定内核与配置即可进入系统。
- **命令行回滚**：
  ```bash
  sudo nixos-rebuild switch --rollback
  ```

---

## 已知事项与硬件特性 (CF-SV8)
1. **CPU**：Intel Core i7-8665U (Whiskey Lake, 4C/8T)
2. **内存**：16GB LPDDR3 (板载)，已配置 ZRAM 50% 动态压缩交换空间防 OOM。
3. **硬盘**：256GB SATA SSD (`sda`)，已启用系统级 `fstrim.weekly`。
4. **键盘**：机身搭载日文 JIS 物理键盘，已在 `modules/input.nix` 中设为 `jp106`。
5. **睡眠**：固件支持 S3 `deep` 睡眠与 `s2idle`。
6. **触摸板**：搭载松下经典圆形触摸板，当前基线使用 libinput，后续阶段将在 X11 下通过 synaptics 驱动激活圆形圆周滚动。
