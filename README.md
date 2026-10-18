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
| 键盘物理布局 (JIS/US) | `modules/input.nix` | §1. 键盘布局 (`xkb.layout`) |
| 触摸板参数与滚动行为 | `modules/input.nix` | §2. 触摸板基础设置 |
| 睡眠模式 (deep / s2idle) | `modules/power.nix` | §1. 睡眠模式基线 |
| 省电策略 (TLP) | `modules/power.nix` | §2. 电源管理骨架 |
| 桌面组件与快捷键 | `modules/desktop-dwm.nix` | 阶段 2 展开 |
| 字体安装与回退顺序 | `modules/fonts-ime.nix` | §1. 字体包与 Fontconfig 默认值 |
| 输入法引擎与词库插件 | `modules/fonts-ime.nix` | §2. Fcitx5 输入法 |
| 蓝牙开关与默认行为 | `modules/services.nix` | §1. 网络与蓝牙 |
| 音频配置 (PipeWire) | `modules/services.nix` | §2. 音频子系统 |

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
