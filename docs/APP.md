# Panasonic Let's Note CF-SV8 系统软件清单与应用职责手册 (APP Manual)

本文档全面记录了系统（NixOS + DWM）中当前安装与启用的所有软件，详细说明了各软件的**核心职责（作业场景）**、**呼出/运行方式**、**配置文件映射**以及**系统资源与开销特性**，作为日常使用与按需精简的权威参考。

---

## 目录索引

- [一、 日常桌面与图形应用](#一-日常桌面与图形应用)
- [二、 游戏平台与模拟器](#二-游戏平台与模拟器)
- [三、 硬件虚拟化与虚拟机支持 (KVM)](#三-硬件虚拟化与虚拟机支持-kvm)
- [四、 开发语言、编译器与编辑器](#四-开发语言编译器与编辑器)
- [五、 终端运维、系统监控与硬件排障](#五-终端运维系统监控与硬件排障)
- [六、 DWM 极简平铺桌面核心基础设施](#六-dwm-极简平铺桌面核心基础设施)
- [七、 松下 CF-SV8 专有硬件驱动与工具](#七-松下-cf-sv8-专有硬件驱动与工具)
- [八、 最近精简记录与恢复指南](#八-最近精简记录与恢复指南)

---

## 一、 日常桌面与图形应用

| 软件名称 | 核心职责与作业场景 | 启动方式 | 配置文件与模块位置 |
| :--- | :--- | :--- | :--- |
| **`google-chrome`** | **全局默认 Web 浏览器兼默认 PDF 阅读器**。<br>接管系统网页浏览、在线音视频播放、文档查阅与内嵌 PDF 阅读，硬件加速成熟稳定。 | `Super + p` 输入 `google-chrome` 回车，或终端输入 `google-chrome` | [`modules/base.nix`](file:///home/flynn/nixos-config/modules/base.nix#L123)<br>MIME 关联：[`modules/services.nix`](file:///home/flynn/nixos-config/modules/services.nix#L39-L46) |
| **`ayugram-desktop`** | **Telegram 增强型即时通讯桌面客户端**。<br>提供反撤回消息查看、反删除媒体流、隐藏已读状态（幽灵模式）、免广告等深度定制的高效通讯作业。 | `Super + p` 输入 `ayugram-desktop` | [`modules/services.nix`](file:///home/flynn/nixos-config/modules/services.nix#L85) |
| **`anki`** | **艾宾浩斯间隔重复记忆卡片学习软件**。<br>用于语言词汇背诵、技术知识点强化、考试卡片复习，基于遗忘曲线动态调度复习作业。 | `Super + p` 输入 `anki` | [`modules/services.nix`](file:///home/flynn/nixos-config/modules/services.nix#L86) |
| **`newsflash`** | **现代化 GTK4 / Libadwaita 原生 RSS 资讯阅读器**。<br>聚合技术博客、开源项目 Release 与新闻资讯，支持离线阅读与 Feedly / Miniflux / 本地同步。 | `Super + p` 输入 `io.gitlab.news_flash.NewsFlash` | [`modules/services.nix`](file:///home/flynn/nixos-config/modules/services.nix#L83) |
| **`qbittorrent-enhanced`** | **增强版 BT / 磁力链下载客户端**。<br>提供强大的 P2P 下载引擎，内置自动屏蔽吸血客户端（迅雷/百度等）黑名单规则，保障优质节点做种与高速下载作业。 | `Super + p` 输入 `qbittorrent` | [`modules/services.nix`](file:///home/flynn/nixos-config/modules/services.nix#L87) |
| **`mpv`** | **极简、低资源开销的本地视频/音频播放器**。<br>无任何冗余 UI 控件，支持 Intel UHD 620 VA-API 硬件级解码，极速渲染高码率 1080p/4K 视频，键盘驱动快捷控制。 | 终端 `mpv <视频文件>` 或关联打开 | [`modules/services.nix`](file:///home/flynn/nixos-config/modules/services.nix#L84)<br>配置：[`dotfiles/mpv/mpv.conf`](file:///home/flynn/nixos-config/dotfiles/mpv/mpv.conf) |
| **`pcmanfm`** | **极轻量图形文件管理器**。<br>毫秒级冷启动，支持多标签页浏览、文件移动复制、压缩解压交互与 U 盘目录图形化查看。 | `Super + p` 输入 `pcmanfm` | [`modules/services.nix`](file:///home/flynn/nixos-config/modules/services.nix#L82) |
| **`localsend`** | **局域网跨设备安全免配互传工具**。<br>无需连接外网与注册账户，通过局域网自动发现手机、平板与其他 PC，快速互传图片、视频与大文件。 | `Super + p` 输入 `localsend_app` | [`modules/services.nix`](file:///home/flynn/nixos-config/modules/services.nix#L54-L57) |
| **`clash-verge`** | **系统级科学上网代理客户端 (Clash Verge Rev)**。<br>以 systemd 系统服务安全托管 TUN 虚拟网卡模式，接管全局流量透明代理，防止普通用户态 White-Screen 渲染闪烁。 | `Super + p` 输入 `clash-verge`，后台开机静默常驻 | [`modules/services.nix`](file:///home/flynn/nixos-config/modules/services.nix#L61-L74) |

---

## 二、 游戏平台与模拟器

| 软件名称 | 核心职责与作业场景 | 启动方式 | 配置文件与模块位置 |
| :--- | :--- | :--- | :--- |
| **`steam`** | **Steam 官方游戏平台与 Proton 兼容运行环境**。<br>提供完整的 Steam 客户端生态，内置 Valve Proton 兼容层，支持在 Linux 下直接畅玩 Windows 平台游戏与独立游戏。 | `Super + p` 输入 `steam` | [`modules/services.nix`](file:///home/flynn/nixos-config/modules/services.nix#L91-L96) |
| **`yuzu-ea`** | **Nintendo Switch 游戏主机模拟器 (EA-4176 最终巅峰版)**。<br>预包装 AppImage 运行库补齐，提供 Vulkan 图形后端，用于离线模拟运行 Nintendo Switch 游戏。 | `Super + p` 输入 `yuzu`，或终端执行 `yuzu` | [`modules/emulation.nix`](file:///home/flynn/nixos-config/modules/emulation.nix#L26) |
| **`appimage-run`** | **NixOS 通用 AppImage 二进制沙盒执行器**。<br>解决 NixOS 独特的 `/nix/store` 目录结构与标准 Linux FHS 路径不一致的问题，支持直接一键执行任何第三方 AppImage 单文件程序。 | 终端 `appimage-run <程序.AppImage>` | [`modules/emulation.nix`](file:///home/flynn/nixos-config/modules/emulation.nix#L25) |

---

## 三、 硬件虚拟化与虚拟机支持 (KVM)

> [!NOTE]
> 系统采用 Linux 原生硬件级虚拟化架构，性能极度逼近裸机，专为在 CF-SV8 上低功耗、免重启运行 Windows 10 IoT LTSC 客户机设计。

| 软件/组件 | 核心职责与作业场景 | 启动与交互方式 | 配置文件与模块位置 |
| :--- | :--- | :--- | :--- |
| **`libvirtd` (`qemu_kvm`, `swtpm`)** | **KVM 硬件虚拟化后端守护进程**。<br>调用 Intel VT-x 硬件虚拟化扩展，负责底层 CPU 指令穿透调度与内存管理；`swtpm` 负责为虚拟机提供虚拟 TPM 2.0 安全芯片。 | 由 systemd 后台自动按需拉起 (`libvirtd.service`) | [`modules/virtualisation.nix`](file:///home/flynn/nixos-config/modules/virtualisation.nix#L7-L13) |
| **`virt-manager`** | **虚拟机图形管理控制台 (Virtual Machine Manager)**。<br>提供直观的 GUI 用于新建虚拟机、分配 CPU/内存、挂载虚拟磁盘与 ISO 镜像、拍快照与恢复。 | `Super + p` 输入 `virt-manager` | [`modules/virtualisation.nix`](file:///home/flynn/nixos-config/modules/virtualisation.nix#L16) |
| **`virt-viewer` & `spice`** | **超低延迟虚拟机交互客户端与传输协议**。<br>负责在宿主机与虚拟机之间提供高帧率桌面画面流转、宿主与虚拟机双向剪贴板同步、以及动态分辨率自适应。 | 随 Virt-Manager 打开控制台自动调用 | [`modules/virtualisation.nix`](file:///home/flynn/nixos-config/modules/virtualisation.nix#L28-L31) |
| **`virtio-win`** | **Windows 专属 VirtIO 半虚拟化高速驱动光盘**。<br>提供软链接直达镜像 `/run/current-system/sw/share/virtio-win/virtio-win.iso`，安装 Windows 客户机时加载此驱动可让虚拟磁盘与虚拟网卡达到物理级吞吐。 | 虚拟机光驱挂载上述软链接路径 | [`modules/virtualisation.nix`](file:///home/flynn/nixos-config/modules/virtualisation.nix#L32-L38) |

---

## 四、 开发语言、编译器与编辑器

| 软件名称 | 核心职责与作业场景 | 启动方式 | 配置文件与模块位置 |
| :--- | :--- | :--- | :--- |
| **`alacritty`** | **系统默认 GPU 渲染终端模拟器**。<br>纯 Rust 编写，毫秒级响应，已定制 12px 舒适呼吸边距与 Catppuccin 优雅配色，桌面核心工作载体。 | `Super + Shift + Return` 极速呼出 | [`modules/base.nix`](file:///home/flynn/nixos-config/modules/base.nix#L120)<br>配置：[`dotfiles/alacritty/alacritty.toml`](file:///home/flynn/nixos-config/dotfiles/alacritty/alacritty.toml) |
| **`neovim`** | **现代极速终端文本编辑器**。<br>原生支持 Lua 配置、LSP 语言服务器协议、异步插件体系，终端下日常编写代码与系统配置的核心利器。 | 终端执行 `nvim <文件名>` | [`modules/base.nix`](file:///home/flynn/nixos-config/modules/base.nix#L121) |
| **`vim`** | **经典系统级文本编辑器**。<br>极小体积（~30MB），不依赖复杂运行时，作为救援模式与极端环境下的基础编辑保障。 | 终端执行 `vim <文件名>` | [`modules/base.nix`](file:///home/flynn/nixos-config/modules/base.nix#L105) |
| **`vscode`** | **Visual Studio Code 全功能图形 IDE**。<br>具备极其丰富的扩展插件生态、图形化断点调试、Git 交互式合并审查与大型项目工程化开发。 | `Super + p` 输入 `code` | [`modules/base.nix`](file:///home/flynn/nixos-config/modules/base.nix#L122) |
| **`gcc`, `gdb`, `gnumake`, `cmake`** | **C/C++ 语言工具链与构建套件**。<br>负责 C/C++ 程序的编译链接、单步断点调试、Makefile 工程与 CMake 现代化构建（同时服务于本地源码定制编译）。 | 终端执行 `gcc`, `gdb`, `make`, `cmake` | [`modules/base.nix`](file:///home/flynn/nixos-config/modules/base.nix#L113-L116) |
| **`cargo`, `rustc`** | **Rust 现代系统级编程语言编译器与包管理器**。<br>负责 Rust 语言工程的构建编译、依赖解析、单元测试与发布打包。 | 终端执行 `cargo`, `rustc` | [`modules/base.nix`](file:///home/flynn/nixos-config/modules/base.nix#L117-L118) |
| **`python3`** | **Python 3 运行时解释器**。<br>用于自动化脚本编写、日常运维任务、数据处理与基础开发。 | 终端执行 `python3` | [`modules/base.nix`](file:///home/flynn/nixos-config/modules/base.nix#L119) |
| **`git`** | **分布式版本控制系统**。<br>管理本项目（`nixos-config`）以及日常软件工程的全部版本提交、分支归档与远程同步。 | 终端执行 `git` | [`modules/base.nix`](file:///home/flynn/nixos-config/modules/base.nix#L95) |
| **`direnv` (`nix-direnv`)** | **目录级自动化开发环境加载器**。<br>进入包含 `.envrc` 的项目目录时，自动拉取并激活对应的 `nix-shell` 或 `flake` 开发环境，离开目录自动还原。 | 终端切换目录时自动触发 | [`modules/base.nix`](file:///home/flynn/nixos-config/modules/base.nix#L98-L101) |
| **`nix-ld`** | **非 Nix 预编译二进制文件通用动态链接器**。<br>突破 NixOS 缺少标准 `/lib64/ld-linux-x86-64.so.2` 的限制，让网络下载的标准 Linux 二进制程序直接开箱运行。 | 系统级内核拦截，静默透明生效 | [`modules/base.nix`](file:///home/flynn/nixos-config/modules/base.nix#L82-L90) |

---

## 五、 终端运维、系统监控与硬件排障

| 软件名称 | 核心职责与作业场景 | 启动与使用方式 | 配置文件与模块位置 |
| :--- | :--- | :--- | :--- |
| **`bluetuith`** | **终端 TUI 极简交互式蓝牙管理器**。<br>操作手感完全对齐 `nmtui`，支持键盘上/下键选择设备、`s` 搜索、`c` 连接、`d` 断开、`P` 配对，无需记忆复杂的 CLI 命令。 | 终端执行 `bluetuith` | [`modules/services.nix`](file:///home/flynn/nixos-config/modules/services.nix#L81)<br>操作手册：[`docs/SKILL.md`](file:///home/flynn/nixos-config/docs/SKILL.md) 第六节 |
| **`btop`** | **终端高颜值动态系统资源监视器**。<br>实时动态监控 CPU 各核心利用率、内存使用与 ZRAM 状态、网络吞吐、进程树与磁盘 I/O。 | 终端执行 `btop` | [`modules/base.nix`](file:///home/flynn/nixos-config/modules/base.nix#L111) |
| **`fastfetch`** | **极速硬件拓扑与系统状态信息看板**。<br>冷启动时间仅需几毫秒，输出美观清晰的 NixOS 版本、内核、机型（CF-SV8）、CPU、GPU、内存等硬件规格。 | 终端执行 `fastfetch` | [`modules/base.nix`](file:///home/flynn/nixos-config/modules/base.nix#L112)<br>配置：[`dotfiles/fastfetch/config.jsonc`](file:///home/flynn/nixos-config/dotfiles/fastfetch/config.jsonc) |
| **`tree`** | **终端目录树形递归展示工具**。<br>以直观的 ASCII/Unicode 树形层级展开展示目录与文件结构。 | 终端执行 `tree -L 2` | [`modules/base.nix`](file:///home/flynn/nixos-config/modules/base.nix#L110) |
| **`wget`, `curl`** | **基础命令行网络请求与文件下载工具**。<br>用于从终端快速发起 HTTP/HTTPS 请求、API 调试以及下载脚本或安装包。 | 终端执行 `curl`, `wget` | [`modules/base.nix`](file:///home/flynn/nixos-config/modules/base.nix#L106-L107) |
| **`pciutils`, `usbutils`** | **硬件总线与芯片诊断工具 (`lspci`, `lsusb`)**。<br>用于查看 PCI-E 设备通道与 USB 接口硬件厂商 ID/设备 ID，排障外设识别故障。 | 终端执行 `lspci`, `lsusb` | [`modules/base.nix`](file:///home/flynn/nixos-config/modules/base.nix#L108-L109) |
| **`fwupd`** | **硬件固件升级只读检测守护进程**。<br>用于通过 Linux Vendor Firmware Service (LVFS) 检查系统是否存在主板 BIOS 与外设固件更新。 | 终端执行 `fwupdmgr get-updates` | [`modules/services.nix`](file:///home/flynn/nixos-config/modules/services.nix#L25) |
| **`thermald`** | **Intel 官方轻薄本动态热管理守护进程**。<br>接管松下 ACPI DPTF 温控与硬件风扇节点，低温待机时主动关停风扇（0 RPM 绝对静音），高负荷平滑控温防烫。 | systemd 后台常驻服务 (`thermald.service`) | [`modules/power.nix`](file:///home/flynn/nixos-config/modules/power.nix#L55-L58) |

---

## 六、 DWM 极简平铺桌面核心基础设施

> [!IMPORTANT]
> 本组软件是整个极简平铺桌面运行的骨骼与基石，相互深度协同绑定，**严禁随意剔除**。

| 组件名称 | 核心职责与作业场景 | 交互按键与触发机制 | 配置文件与源码位置 |
| :--- | :--- | :--- | :--- |
| **`dwm`** | **平铺窗口管理器核心**。<br>仅以 2000 余行纯 C 语言编写的高性能 X11 窗口管理器，纯键盘驱动，零内存开销，主从屏（Master/Stack）平铺布局。 | `Super + 1~6` 切换标签<br>`Super + j/k` 焦点流转<br>`Super + Return` 主从对调 | [`modules/desktop-dwm.nix`](file:///home/flynn/nixos-config/modules/desktop-dwm.nix#L299-L301)<br>源码：[`pkgs/dwm/config.h`](file:///home/flynn/nixos-config/pkgs/dwm/config.h) |
| **`dmenu`** | **极速键盘驱动应用启动器与菜单交互**。<br>在屏幕顶部展开单行输入条，支持模糊匹配快速启动系统内任意应用程序或自定义脚本。 | `Super + p` 启动应用<br>`Super + s` 计时器菜单 | [`modules/desktop-dwm.nix`](file:///home/flynn/nixos-config/modules/desktop-dwm.nix#L302-L304)<br>源码：[`pkgs/dmenu/config.h`](file:///home/flynn/nixos-config/pkgs/dmenu/config.h) |
| **`slstatus`** | **极简顶栏状态栏监控系统**。<br>轻量轮询更新音量/耳机状态、Speedrun 跑表与番茄钟、电池电量（BAT1）、时间日期。 | 登录桌面时后台自启 | [`modules/desktop-dwm.nix`](file:///home/flynn/nixos-config/modules/desktop-dwm.nix#L305-L311)<br>源码模板：[`pkgs/slstatus/config.h.in`](file:///home/flynn/nixos-config/pkgs/slstatus/config.h.in) |
| **`picom`** | **GLX 硬件后端 VSync 垂直同步合成器**。<br>彻底根除全屏滚动与视频播放时的画面撕裂（Tearing），同时强制关闭阴影与渐变动画，实现零视觉延迟与最低耗电。 | 桌面登录时后台自启 | [`modules/desktop-dwm.nix`](file:///home/flynn/nixos-config/modules/desktop-dwm.nix#L384-L398) |
| **`slock` & `xss-lock`** | **极简高安全性锁屏与空闲/休眠联动守护**。<br>黑屏彻底屏蔽所有按键与鼠标事件，输入当前用户密码回车解锁；盒盖或超时自动唤起锁屏。 | `Super + Shift + l` 手动锁屏；盒盖自动触发 | [`modules/desktop-dwm.nix`](file:///home/flynn/nixos-config/modules/desktop-dwm.nix#L363-L365,L400) |
| **`dwm-screenshot` (`maim` + `satty` + `xclip`)** | **截图标注交互流一体化工具链**。<br>按下快捷键选区截图，立即唤起轻量 Satty 标注器（支持画箭头、矩形、马赛克、画笔），完成后回车自动复制到剪贴板并归档保存。 | `PrtScn` 交互式选区截图<br>`Shift + PrtScn` 截取全屏 | [`modules/desktop-dwm.nix`](file:///home/flynn/nixos-config/modules/desktop-dwm.nix#L55-L78)<br>归档目录：`~/Pictures/Screenshots` |
| **`speedrun-timer` (`timer`)** | **Speedrun 竞速跑表与倒计时系统**。<br>纯 Bash 5 `$EPOCHSECONDS` 毫秒级原生实现，顶栏实时显示状态与图标，倒计时归零时通过 Dunst 桌面悬浮窗发出强提醒。 | `Super + s` 打开单行菜单 (1h/2h/4h)<br>`Super + Shift + s` 暂停/继续<br>终端输入 `timer 1h` 或 `timer run` | [`modules/desktop-dwm.nix`](file:///home/flynn/nixos-config/modules/desktop-dwm.nix#L81-L296) |
| **`feh`** | **自包含桌面壁纸加载工具**。<br>在 X11 会话启动时将仓库自包含壁纸平铺渲染至根窗口。 | 会话启动自动加载 | [`modules/desktop-dwm.nix`](file:///home/flynn/nixos-config/modules/desktop-dwm.nix#L358) |
| **`dunst` & `libnotify`** | **极简桌面通知守护进程与 notify-send 工具**。<br>接收来自系统、计时器与应用程序的桌面悬浮弹窗提醒，支持快捷键关闭。 | 后台常驻守护 | [`modules/desktop-dwm.nix`](file:///home/flynn/nixos-config/modules/desktop-dwm.nix#L361,L415-L416) |
| **`udiskie` & `udisks2`** | **可移动存储设备即插即用自动挂载服务**。<br>插入 U 盘或移动硬盘时自动在 `/run/media/flynn/` 建立挂载点，拔出前安全卸载。 | 后台静默守护进程 | [`modules/desktop-dwm.nix`](file:///home/flynn/nixos-config/modules/desktop-dwm.nix#L367)<br>服务：[`modules/services.nix`](file:///home/flynn/nixos-config/modules/services.nix#L34) |
| **`brightnessctl`** | **屏幕背光平滑无级调节工具**。<br>绑定笔记本硬件 Fn+F1 / Fn+F2 亮度调节按键，调整 Intel 核显面板背光。 | `Fn + F1` 降亮度<br>`Fn + F2` 升亮度 | [`modules/desktop-dwm.nix`](file:///home/flynn/nixos-config/modules/desktop-dwm.nix#L410) |
| **`adwaita-icon-theme`** | **原生低延迟暗色光标与图标主题**。<br>彻底消除大尺寸光标切换时的位图重绘阻滞感，全局统一 24px Adwaita 原生光标。 | 全局环境固化 | [`modules/appearance.nix`](file:///home/flynn/nixos-config/modules/appearance.nix#L20-L33) |

---

## 七、 松下 CF-SV8 专有硬件驱动与工具

> [!NOTE]
> 本组工具专为 **Panasonic Let's Note CF-SV8** 硬件机身定制。如果系统迁移至其他机型，此文件是唯一需要解耦的宿主配置。

| 驱动/工具名称 | 核心职责与作业场景 | 配置文件与模块位置 |
| :--- | :--- | :--- |
| **`panasonic_laptop`** | **松下独占 WMI / ACPI 平台内核驱动**。<br>负责对接 Let's Note 机身专有传感器、电池温控、以及 Fn 硬件功能热键。 | [`hosts/sv8/sv8.nix`](file:///home/flynn/nixos-config/hosts/sv8/sv8.nix#L11) |
| **`xf86-input-synaptics` & `xinput`** | **松下经典圆盘触摸板环形旋转手势驱动**。<br>替代通用 libinput 驱动，原生支持在圆形触控板边缘**顺时针划圈向下滚动**、**逆时针划圈向上滚动**，以及掌压防误触调谐。 | [`hosts/sv8/sv8.nix`](file:///home/flynn/nixos-config/hosts/sv8/sv8.nix#L28-L52,L90-L91) |
| **`intel-media-driver` & `libvdpau-va-gl`** | **Intel Whiskey Lake UHD 620 核显硬件视频解码驱动 (VA-API)**。<br>硬解处理 VP9、H.264 与 HEVC 视频流，将视频解码工作从 CPU 卸载至核显执行单元，显著降低看视频时的发热并大幅延长续航。 | [`hosts/sv8/sv8.nix`](file:///home/flynn/nixos-config/hosts/sv8/sv8.nix#L15-L18) |
| **`dvdplusrwtools`, `cdrkit`, `xorriso`** | **机身内置 9.5mm 超薄 SATA 刻录光驱免提权工具链**。<br>支持主用户直接免 sudo 烧录 DVD+R/DVD-R 光盘，原生提供 `growisofs`、`mkisofs` 与 `genisoimage` 实时打包刻录作业。 | [`hosts/sv8/sv8.nix`](file:///home/flynn/nixos-config/hosts/sv8/sv8.nix#L82-L96)<br>实操手册：[`docs/DVD-BURNING.md`](file:///home/flynn/nixos-config/docs/DVD-BURNING.md) |

---

## 八、 最近精简记录与恢复指南

### 1. 已精简的应用与组件

| 精简组件 | 精简原因与收益 | 恢复方法 |
| :--- | :--- | :--- |
| **Firefox 浏览器** | 系统全局已统一采用 Google Chrome 作为默认 Web 浏览器兼 PDF 阅读器，移除重复冗余组件。 | 在 [`modules/services.nix`](file:///home/flynn/nixos-config/modules/services.nix) 添加 `programs.firefox.enable = true;` |
| **Docker 容器引擎** | 近期无容器使用场景，移除 `dockerd` 后台守护进程与 `docker-compose`，减少开机后台进程与套接字监听开销。*(注意：KVM / Virt-Manager 虚拟机完整保留)* | 详见 [docs/DOCKER.md](DOCKER.md) 第二节，在 [`modules/virtualisation.nix`](file:///home/flynn/nixos-config/modules/virtualisation.nix) 重新开启 `virtualisation.docker.enable = true;` |

---
*文档生成规范：严格遵循 NixOS 声明式追踪标准与 CF-SV8 纯粹极客美学。*
