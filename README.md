# Panasonic Let's Note CF-SV8 NixOS 配置仓库

本仓库声明式管理 Panasonic Let's Note CF-SV8 (CFSV8-2 / `CF-SV8SFKVS`) 的 NixOS 系统配置与 X11 + DWM 桌面环境。

---

## 5 分钟阅读导览

如果你第一次接手或修改本仓库，请按以下顺序阅读：

### 1. 先看哪几个文件？
1. **[hosts/sv8/sv8.nix](hosts/sv8/sv8.nix)**：
   - 唯一的 CF-SV8 本机特有配置：包含松下圆盘触摸板驱动与滚动灵敏度、S3 深度睡眠、144 DPI、Intel 核显硬件加速、防闪屏补丁与电池节点名。
2. **[modules/desktop-dwm.nix](modules/desktop-dwm.nix) 与 [pkgs/dwm/config.h](pkgs/dwm/config.h)**：
   - 通用平铺桌面：负责 DWM 窗口管理器、快捷键、字体字号 (11pt)、壁纸自包含加载、锁屏 (`slock`) 与 Alacritty 极速终端。
3. **[modules/power.nix](modules/power.nix)**：
   - 通用电源管理：固化原厂 10W 冷凉静音策略，结合 TLP 能效调度与 UPower，整机待机功耗低至 ~5.15W，兼顾极致低温与长续航。
4. **[modules/services.nix](modules/services.nix) 与 [modules/base.nix](modules/base.nix)**：
   - 通用系统服务与开发环境：负责网络、音频、PCManFM 文件管理、Zathura PDF 查看器、Git 以及按项目轻量加载环境的 `direnv`。

### 2. 最容易改错的 3 个地方（避坑指南）
1. **修改 DWM 源码后忘记 rebuild 或误加进 packages**：
   - DWM 是通过 NixOS 模块内部的 `.override` 直接使用源码编译并注入会话的。**绝对不要**把 `dwm` 写入 `environment.systemPackages`，否则定制的 `config.h` 会被官方默认二进制覆盖而失效。修改 `pkgs/dwm/config.h` 后，必须执行 `sudo nixos-rebuild switch --flake ~/nixos-config#sv8` 重新编译生效。
2. **新增文件未执行 `git add`**：
   - Nix Flake 具有极高的严谨性，仅能感知被 Git 跟踪的文件。若在仓库中新增了模块、补丁或图片，**必须先运行 `git add <新文件>`**，否则 rebuild 时会直接报错找不到该文件。
3. **触控板驱动冲突**：
   - 松下独有的圆盘边缘顺畅滚动完全依赖 `xf86-input-synaptics`。`hosts/sv8/sv8.nix` 中 `services.libinput.enable` **必须严格保持为 `false`**。若不慎开启了 libinput，两者会抢占触摸板导致圆周旋转滚动完全失效。

---

## 目录结构

```
~/nixos-config
├── flake.nix / flake.lock            # Flake 入口（导出 sv8 与 template 主机）与依赖锁文件
├── README.md                          # 说明文档、改配置速查表、回滚指南、5分钟导览
├── CHECKLIST.md                       # 各阶段任务执行活副本（全项已验证）
├── NOTES.md                           # 硬件全功能对照表、实测数据、决策记录与原理解析
├── docs/                              # 系统与硬件专项指南
│   └── DVD-BURNING.md                 # DVD+R 光盘刻录、防睡眠与数据校验指南
├── wallpapers/                        # 桌面壁纸资源目录（仓库自包含，随构建打包进系统）
├── dotfiles/                          # 用户级应用核心配置 (fastfetch, alacritty, mpv, zathura)
├── hosts/
│   ├── sv8/
│   │   ├── default.nix                # SV8 主机入口（只做 imports、hostName、stateVersion）
│   │   ├── sv8.nix                    # 唯一的 CF-SV8 本机特有配置（微码、松下驱动、核显、圆盘、S3、BAT1、光驱）
│   │   └── hardware-configuration.nix # 硬件扫描生成的分区与内核模块配置
│   └── template/
│       ├── default.nix                # 新电脑接入模板起点（仅引用通用模块，无任何本机特有项）
│       └── hardware-configuration.nix # 硬件占位配置（新机部署时由扫描生成覆盖）
├── modules/
│   ├── default.nix                    # 通用模块统一汇总入口（多主机一行即可引入全部通用模块）
│   ├── base.nix                       # Nix 设置、引导上限、通用固件、ZRAM 内存优化、fstrim、时区、用户与 PKI
│   ├── graphics.nix                   # 通用图形栈支持与 autorandr 外接显示器自动配置
│   ├── input.nix                      # 通用美式 US 键盘布局与控制台键位（通用机型 libinput 默认开启）
│   ├── power.nix                      # 通用电源监控 (UPower)、logind 电源事件、TLP 节能策略与外设防休眠
│   ├── desktop-dwm.nix                # DWM 窗口管理器、读取 host DPI（默认 96）、壁纸、picom、slock
│   ├── fonts-ime.nix                  # 中日韩全套字体（Noto CJK）、Fontconfig 回退优先级（免打字输入法）
│   ├── services.nix                   # NetworkManager、蓝牙、PipeWire 音频、PCManFM、Zathura、Clash Verge
│   └── appearance.nix                 # macOS 样式光标主题 (apple-cursor)、X11/XRDB 与 GTK3/4 样式统一
└── pkgs/                              # 本地自定义包与源码配置树
    ├── dwm/config.h                   # DWM 核心按键绑定与工作区 (1~6)
    ├── dmenu/config.h                 # dmenu 配色与字体
    └── slstatus/config.h.in           # 状态栏监控模板（@batteryName@ 由 Nix 选项 my.batteryName 动态替换）
```

---

## 改配置速查表

| 想修改的内容 | 对应文件路径 | 所在小节或参数 |
| :--- | :--- | :--- |
| **电源能效与 EPP 调频策略** | `modules/power.nix` | §2. TLP 设置 (`eppOnAc` / `eppOnBat`) |
| **开机引导项保留代数** | `modules/base.nix` | 顶部 `let bootLimit = 3;` |
| **用户与 sudo 权限 / 用户组** | `modules/base.nix` | §5. 用户与权限 (`users.users.flynn`) |
| **系统预装 CLI 工具 / 开发包** | `modules/base.nix` | §6. 基础系统工具 (`systemPackages`) |
| **图形文件管理 / PDF / 日常软件** | `modules/services.nix` | §6. PCManFM、Zathura、MPV 等日常应用 |
| **键盘映射布局 (标准美式 US)** | `modules/input.nix` | §1. 键盘布局 (`xkb.layout`) |
| **圆形滚动灵敏度 / 触发方式** | `hosts/sv8/sv8.nix` | §4. 圆盘触摸板 (`CircScrollDelta = "0.2"`) [这条属于 sv8.nix] |
| **屏幕缩放比例 (全局 DPI)** | `hosts/sv8/sv8.nix` | §3. 显示设置 (`services.xserver.dpi = 144`) [这条属于 sv8.nix] |
| **S3 深度睡眠 / 内核参数** | `hosts/sv8/sv8.nix` | §5. 睡眠与内核参数 (`mem_sleep_default=deep`) [这条属于 sv8.nix] |
| **状态栏电池节点名称** | `hosts/sv8/sv8.nix` | §6. 电池节点名称 (`my.batteryName = "BAT1"`) [这条属于 sv8.nix] |
| **内置光驱与 DVD 刻录** | `hosts/sv8/sv8.nix` | §7. 内置光驱与免提权刻录工具集 (`dvdplusrwtools` / `xorriso`)，指南见 [docs/DVD-BURNING.md](docs/DVD-BURNING.md) [这条属于 sv8.nix] |
| **合盖睡眠与电源键行为** | `modules/power.nix` | §1. 睡眠模式与合盖锁屏 (`services.logind`) |
| **USB 供电与外设防休眠** | `modules/power.nix` | §3. 内核级与 Udev 物理锁 (`usbcore.autosuspend=-1`) |
| **鼠标指针主题与尺寸** | `modules/appearance.nix` | §1~§3 (`cursorTheme = "Adwaita"`, `cursorSize = 24`) |
| **桌面壁纸图片** | `wallpapers/` 目录 | 替换图片或修改 `modules/desktop-dwm.nix` 的 `wallpaperPath` |
| **DWM 快捷键、窗口排版** | `pkgs/dwm/config.h` | `keys[]` 数组定义 |
| **终端模拟器 (Alacritty) 字体/字号/边距** | `~/.config/alacritty.toml` | `[font]` 与 `[window.padding]`（热加载免编译） |
| **应用菜单 (dmenu) 配色与字体** | `pkgs/dmenu/config.h` | `colors[]` 与 `font` |
| **状态栏 (slstatus) 监控信息** | `pkgs/slstatus/config.h.in` | `args[]` 数组 |
| **字体安装与 CJK 回退优先级** | `modules/fonts-ime.nix` | §1. 字体包与 Fontconfig 默认值 |

---

## 电源管理与能效策略 (固化 10W 冷凉静音)

针对松下 CF-SV8 轻薄镁合金机身特性，本配置彻底固化了**原厂 10W 冷凉静音与超长续航策略**，移除了第三方功耗覆写守护进程：

- **持续功耗**：稳定释放 10W，CPU 全核 1.6~1.7 GHz，外壳低于 48°C，风扇几乎保持停转或微风静音。
- **低功耗深度驻留**：结合 TLP 电源调度与 Intel C-states 优化，CPU 空闲封装仅 ~3W，C10 深度驻留，整机离电空闲功耗低至 **~5.15W**，实测续航可达 7~9 小时。
- **纯净稳定**：100% 依赖 Linux 原生 TLP 与固件调度，无驻留后台的寄存器高频覆写循环，杜绝系统不稳定隐患。

---

## DWM 常用快捷键对照表

> [!TIP]
> 包含 DWM 窗口管理、松下硬件 Fn 热键、圆盘触控板手势、Zathura PDF 全套 Vim 键位与 Alacritty 技巧的完整手册请查阅专用技能文件：[docs/SKILL.md](docs/SKILL.md)（或快捷链接 [docs/SHORTCUTS.md](docs/SHORTCUTS.md)）。

| 快捷键 | 功能 | 说明 |
| :--- | :--- | :--- |
| `Super + Shift + Enter` | 打开终端 | 启动 GPU 加速 Alacritty 极速终端 |
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

### 6. Git 提交与 Generation 代数关联规范
为了方便回溯每次代码变更所对应的具体系统版本，本仓库约定每次提交均标注生效的系统代数：
- 规范格式：`<type>(<scope>): <描述> (Gen <代数>)`，例如 `feat(services): update xxx (Gen 52)`。
- 自动化钩子：仓库已配置 `.git/hooks/prepare-commit-msg`，日常提交时会自动抓取当前激活的 Generation 注入提交信息，确保 Git 提交记录与系统代数严格一一对应。

---

## 新机安装与跨机器复现指南

本配置基于纯函数式 Nix Flake 构建，通过 `flake.lock` 严格锁定了全部软件包哈希，具备 **100% 确定性复现能力**。

### 场景 A：在另一台松下 CF-SV 系列或重装本机时（零硬件改动）

只需关注**新磁盘的分区 UUID**：

1. **克隆配置仓库**：
   ```bash
   git clone <本仓库地址> ~/nixos-config
   cd ~/nixos-config
   ```
2. **更新新机器的磁盘硬件配置**：
   ```bash
   # 生成当前新机器的实际磁盘 UUID 与分区映射
   nixos-generate-config --show-hardware-config > hosts/sv8/hardware-configuration.nix
   ```
3. **一键构建并应用系统**：
   ```bash
   sudo nixos-rebuild switch --flake .#sv8
   ```
4. **设置用户登录密码**（首装必需）：
   ```bash
   sudo passwd flynn
   ```
5. **重启生效**：
   系统开机自动以 tty1 登录并拉起 DWM 桌面，壁纸、字体、Alacritty GPU 极速终端、松下圆盘旋转滚动均 100% 还原。

---

### 场景 B：新电脑快速接入（5 步接入指南）

得益于 `hosts/sv8/sv8.nix` 与通用 `modules/` 的彻底解耦，为任意新电脑（ThinkPad、普通 PC、虚拟机等）复现极简桌面仅需 5 步：

1. **复制模板目录**：
   ```bash
   cp -r hosts/template hosts/<新主机名>
   ```
2. **生成硬件配置**：
   ```bash
   nixos-generate-config --show-hardware-config > hosts/<新主机名>/hardware-configuration.nix
   ```
3. **修改主机名**：
   编辑 `hosts/<新主机名>/default.nix`，设置：
   ```nix
   networking.hostName = "<新主机名>";
   ```
4. **加入 flake.nix 入口**：
   在 `flake.nix` 的 `outputs.nixosConfigurations` 中添加：
   ```nix
   nixosConfigurations.<新主机名> = nixpkgs.lib.nixosSystem {
     system = "x86_64-linux";
     modules = [ ./hosts/<新主机名> ];
   };
   ```
5. **编写本机特有配置**：
   若该机器有特有硬件（如 CPU 微码、独立显卡驱动、屏幕特定 DPI 等），新建 `hosts/<新主机名>/<新主机名>.nix` 并在 `hosts/<新主机名>/default.nix` 中引入；通用项无需重复编写，直接复用 `modules/`。


---

## 已知事项与硬件特性 (CF-SV8)
1. **CPU**：Intel Core i7-8665U (Whiskey Lake, 4C/8T)，固化原厂 10W 冷凉静音与超长续航。
2. **内存**：16GB LPDDR3 (板载)，已配置 ZRAM 50% 动态压缩交换空间防 OOM。
3. **硬盘**：256GB SATA SSD (`sda`)，已启用系统级 `fstrim.weekly`。
4. **键盘**：采用标准美式 US 键盘布局（`layout = "us"`），完全移除 Fcitx5，保留全套 CJK 字体用于清晰阅读。
5. **睡眠**：固件原生支持 S3 `deep` 睡眠与 `s2idle`，合盖与电源键唤起挂起，开盖即唤醒。
6. **触摸板**：搭载松下经典圆形触摸板，已通过 `xf86-input-synaptics` 驱动原生激活经典圆盘边缘旋转滚动（くるくるスクロール，步进设置为 `0.2`）。
7. **指纹与无线滑块**：本机硬件未配备指纹模块；侧面无线滑块在 Linux 下仅物理断开蓝牙，Wi-Fi 统一由 NetworkManager / rfkill 软件管理。
