# SV8 NixOS + DWM 配置任务检查清单 (CHECKLIST)

## 阶段 0 — 盘点与提问（只读，不改任何东西）
- [x] 运行并把结果存入 `NOTES.md` 的「硬件盘点」：`nixos-version`、`uname -r`、`lscpu`、`lspci -nnk`、`lsusb`、`sudo dmidecode -t system -t bios`、`lsblk -f`、`free -h`、`ls /sys/class/power_supply`、`cat /sys/power/mem_sleep`、`bootctl status`、`ls /etc/nixos`、`nmcli device`、`rfkill list`
- [x] 判断是否存在：指纹、红外/人脸相机、WWAN、Thunderbolt、SD 读卡器；内存 8/16GB；SSD 是 SATA 还是 NVMe
- [x] 备份当前 `configuration.nix`（放仓库 `legacy/`），不删除
- [x] 向我提问（附默认值）：用户名 / 主机名（默认沿用）、是否用 flakes（默认是）、nixpkgs 分支（默认沿用当前稳定版）、是否用 home-manager（默认不用，先系统级）、物理键盘 JIS/US、时区（先用 `timedatectl` 查当前值）、输入法（默认中文拼音，日语可选）、续航 vs 性能偏好（默认续航优先）、是否需要休眠（默认不要）、登录方式（默认 tty 自动登录 + startx，备选 lightdm / ly）

## 阶段 1 — 仓库与基线
- [x] 初始化 git 仓库、flake、模块骨架（模块可先为空，但要有文件头和分节标题）；新增文件记得 `git add`
- [x] 启用 flakes 与 nix-command；`nix.settings` 合理；先不开自动 GC，清理策略写进注释
- [x] 引导：保持当前方式；设置保留代数上限，先看 `df -h /boot` 的空间
- [x] 把现有硬件配置和现有行为**等价**迁入（本步不加新功能）。流程：静态检查 → 我执行 `test` → 我确认后执行 `switch` → 我重启一次确认能进系统 → `git tag baseline`
- [x] 基础项：时区、locale（`en_US.UTF-8` + `zh_CN.UTF-8`）、用户与 sudo、NetworkManager、`fstrim`、`zramSwap`、`enableRedistributableFirmware`、Intel 微码、`fwupd`（只读检查，不自动刷）

## 阶段 2 — 图形与 DWM（X11）
- [x] 图形栈：`hardware.graphics`（核实选项名）、`intel-media-driver`（VAAPI）、X 驱动用 modesetting、不装 xf86-video-intel。验证：`vainfo`、`glxinfo -B`、`xrandr --verbose`
- [x] DPI / 缩放：12.1 寸 1920×1200 约 187 DPI，默认 96 太小。已设为 144 DPI（1.5x 缩放）
- [x] 启用 X11 + dwm；dwm / st / dmenu 源码或补丁放仓库内；按我选的登录方式配置；确认 dwm 没出现在 `systemPackages`
- [x] 桌面件逐个加、逐个验证：st（带回滚滚轮补丁）、dmenu、状态栏（slstatus）、锁屏（slock + xss-lock）、壁纸（Kurisu.png）、通知（dunst）、截图（maim + xclip）、剪贴板、自动挂载（udiskie）、音量（PipeWire）、亮度（brightnessctl）、终端 0.8 半透明（picom）
- [ ] 用 `xev` 确认 Fn 键实际 keycode，再写进 dwm `config.h` 的快捷键
- [ ] 闪屏验证：连续使用 ≥ 30 分钟（播放视频、调亮度、插拔 HDMI、睡眠唤醒），记录是否闪
- [ ] （仅在闪屏出现时）用 `specialisation`，由我 rebuild 并在启动菜单选择；每次只改一个变量，按顺序：`i915.enable_psr=0` → 仍闪再加 `i915.enable_fbc=0` → 最后手段 `i915.enable_dc=0`（会增加功耗，需在注释写明）。辅助判断：`journalctl -k | grep -i i915`。结论写进 `graphics.nix` 注释

## 阶段 3 — 输入设备
- [x] 键盘：按用户最新要求采用标准美式 US 键盘布局（`layout = "us"`，无需 JIS 特殊键映射）
- [x] 触摸板基线：`libinput list-devices`、`xinput list`，记录型号与坐标范围（`Synaptics TM3136-020`，坐标 0..880，中心 440,440，尺寸 44×44mm）
- [x] 圆形滚动配置：X11 + synaptics 驱动（`xf86-input-synaptics`），配置 `CircularPad`、`CircularScrolling`、`CircScrollTrigger=0`、`CircScrollDelta=0.1`，禁用冲突的 `libinput`
- [ ] 验证：圆周滚动、点按、双指 / 边缘滚动、拖拽、掌压误触、睡眠唤醒后仍可用
- [ ] 若 synaptics 路线失败：回落 libinput（会失去圆形滚动），把失败原因记入 `NOTES.md` 并告诉我，由我决定

## 阶段 4 — 松下专有硬件
- [ ] `lsmod | grep -i panasonic`、`dmesg | grep -i panasonic`、`ls /sys/devices/platform/panasonic*`：确认 `panasonic_laptop` 是否加载、暴露了哪些接口（背光 / eco 模式等）。只记录，不盲目写
- [ ] 按键测试：用 `evtest` / `xev` 逐个按 Fn 组合键、音量亮度键、无线开关；`journalctl -k -f` 观察 "Unknown hotkey event"。结果整理成映射表写入 `NOTES.md`
- [ ] 亮度：`/sys/class/backlight` 有哪些设备，调节是否平滑
- [ ] Fn+F8（恢复显示设置）用 autorandr 实现；Fn+F9（电量）用通知或状态栏；Fn+F10（休眠）仅当我启用休眠
- [ ] 无线开关（机身侧面滑块）：**先只读调研**。SV7 上它只物理断开蓝牙，Wi-Fi 靠读 EC 寄存器再调 rfkill；SV8 是否一样未知。检查日志中是否有 ACPI 事件，DSDT 中是否有同名方法（`acpidump` + `iasl` 只读）。把调研结果给我看，再决定是否实现（涉及红线 4）
- [ ] 电源键 / 键盘唤醒：SV7 需 `acpi_call`，SV8 路径可能不同，**高风险，默认跳过**。只记录现状：合盖、电源键、键盘、USB 哪些能唤醒
- [ ] 记录是否存在 `/sys/bus/iio/devices`（环境光传感器），不强求
- [ ] 逐项测并记录：摄像头（`v4l2-ctl --list-devices`）、麦克风 / 扬声器（`wpctl status`）、SD 读卡器、HDMI、Type-C / Thunderbolt 3 外接显示器
- [ ] 指纹 / 红外人脸 / WWAN（仅硬件存在时）：记录设备 ID，查是否被 fprintd / Howdy / ModemManager 支持。不支持就如实记录「不可用」，不折腾私有驱动

## 阶段 5 — 电源与散热（先测量，再优化）
- [ ] 基线测量（插电 / 电池各一组，亮度固定 50%，无外设，空闲 5 分钟）：`powertop`、`turbostat`（封装功耗、温度、C-state 驻留）、`/sys/class/power_supply/BAT*/` 的放电功率
- [ ] 电源管理方案二选一，**不要同时开**：默认 TLP（或 power-profiles-daemon）。thermald 先不开，测完再决定
- [ ] TLP 逐项设置并注释：CPU 调度 / EPP、睿频策略、SATA / NVMe 链路省电、PCIe ASPM、Wi-Fi 省电、USB 自动挂起（可能让外设掉线）、声卡省电、充电阈值（仅当固件 / 驱动暴露了接口）。每开一项都让我 rebuild 后重测，无收益或有副作用的不留
- [ ] 功耗上限核查（**只读**）：`/sys/class/powercap/intel-rapl:0/constraint_*_power_limit_uw` 与对应 `constraint_*_name`，`turbostat` 看 PL1 / PL2 与限制原因，记录
- [ ] 压力测试：`stress-ng --cpu $(nproc) --timeout 300s` 同时跑 `turbostat`，观察持续功耗、频率、温度、是否被压在约 10W。插电与电池各做一次
- [ ] 结论汇报：如果持续功耗被限制得远低于 CPU 标称 TDP，判断来源并给我证据：(a) 固件标称（cTDP-down）(b) EC 周期性复位（多次读取看是否被改回）(c) 温度 / 电池降频
- [ ] 是否解除限制由我决定。若同意：先尝试直接写 sysfs；若被改回，再用 `services.throttled`（需关闭 Secure Boot，可能与 thermald 冲突，会开启 MSR 写入）。初始值不超过 Intel ARK 标称 TDP，逐步加；封装温度持续超过 85°C 就回退。风险与回滚写进注释 `# [RISK]`
- [ ] 睡眠：`cat /sys/power/mem_sleep`。若有 `deep`，测 `s2idle` 与 `deep` 各一次（合盖 → 等 10 分钟 → 开盖），记录：能否唤醒、电量下降（`energy_now` 差值）、风扇是否转、显示是否恢复、网络 / 蓝牙 / 触摸板是否恢复。只有 `deep` 明显更好才设 `mem_sleep_default=deep`；若只有 `s2idle`，研究如何让它真正进低功耗（如可用，查 `/sys/kernel/debug/pmc_core/`），不强行
- [ ] 合盖行为、空闲锁屏、低电量动作（`services.logind` / upower）
- [ ] 休眠（可选，仅当我要）：需要磁盘 swap（≥ 内存）和 `resume` 配置。创建 swapfile 前先告诉我占用空间并等批准

## 阶段 6 — 字体与 CJK 阅读支持
- [x] 字体：中日英覆盖（Noto CJK Sans / Serif、等宽字体 + Nerd Font 图标、emoji）；用 `fonts.fontconfig.defaultFonts` 把简体中文字形排在前面。验证：st、浏览器中英混排对齐、不缺字、字形正确
- [x] 输入法变更：按用户最新要求，本机不使用中文打字输入法，已完全移除 Fcitx5，仅保留 CJK 字体满足阅读需求

## 阶段 7 — 日常服务与应用
- [ ] 蓝牙、网络（NetworkManager，命令行 `nmcli` / `nmtui` 即可）、PipeWire 音频；不需要的服务（如打印）不开
- [ ] 浏览器、文件管理、PDF 阅读、编辑器：先问我偏好，不要预装一堆
- [ ] `programs.git` 基础配置；SSH 密钥由我自己生成，不要代劳
- [ ] 开发环境保持最小：按项目用 `nix shell` / `nix develop` / direnv
- [ ] 系统维护：`nix.gc` / `nix.optimise` 策略（保留至少两周的代数，注意 `/boot` 空间）；`system.autoUpgrade` 保持关闭（红线 1）；更新流程写进 README（我手动 `nix flake update` 后先 `build` 与 `test`）

## 阶段 8 — 整理与交付
- [ ] **分类与注释自查**，逐文件核对：
  - 有文件头（路径 / 作用 / 依赖 / 目录），有统一格式的分节标题
  - 没有 `misc` 类杂物文件，同主题选项没有散落
  - 注释简明：不复述代码、没有大段死代码、没有过时说明
  - 可调参数有「可改：」说明，首次出现的 NixOS 概念有 1–2 行解释
  - `[SV8]` / `[TEST]` / `[RISK]` 标记齐全，无秘密
  - 全部 `nixfmt`（可选 `statix` / `deadnix`）
- [ ] 静态检查通过（`nix flake check --no-build`）。请我执行 `build` 与 `switch` 并重启一次；你用只读命令复测关键功能：联网、圆形滚动、亮度键、音量键、睡眠 / 唤醒、输入法
- [ ] `README.md`：目录说明、**改配置速查表**、日常命令（重建 / 更新 / 回滚 / 清理，注明由我手动执行）、新机或重装时如何用本仓库恢复、已知问题与未解决事项
- [ ] 在 `NOTES.md` 整理「硬件功能对照表」：功能 | 状态（正常 / 部分 / 不可用 / 未测）| 方案 | 备注。覆盖：圆形滚动、点按、亮度键、音量键、Fn 键、无线开关、睡眠 / 休眠、唤醒方式、闪屏、功耗上限、放电功率、摄像头、麦克风、扬声器、读卡器、HDMI、Type-C / TB3、指纹、人脸、WWAN
- [ ] 给我一份 5 分钟「阅读导览」：先看哪几个文件、各自改什么、最容易改错的 3 个地方。我看不懂的地方，按我的反馈重写注释
- [ ] 最终 commit，`git tag v1`；告诉我仓库路径和日常用法
