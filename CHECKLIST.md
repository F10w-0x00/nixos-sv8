# SV8 NixOS + DWM 配置任务检查清单 (CHECKLIST)

## 阶段 0 — 盘点与提问（只读，不改任何东西）
- [x] 运行并把结果存入 `NOTES.md` 的「硬件盘点」：`nixos-version`、`uname -r`、`lscpu`、`lspci -nnk`、`lsusb`、`sudo dmidecode -t system -t bios`、`lsblk -f`、`free -h`、`ls /sys/class/power_supply`、`cat /sys/power/mem_sleep`、`bootctl status`、`ls /etc/nixos`、`nmcli device`、`rfkill list`
- [x] 判断是否存在：指纹、红外/人脸相机、WWAN、Thunderbolt、SD 读卡器；内存 8/16GB；SSD 是 SATA 还是 NVMe
- [x] 备份并解构当前 `configuration.nix`，完整迁移至模块化架构并由 Git 历史归档
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
- [x] 用 `xev` 确认 Fn 键实际 keycode，已写入 dwm `config.h` 快捷键（音量、亮度、锁屏、截图）并实测生效
- [x] 闪屏验证：连续使用 ≥ 30 分钟（编译代码、调亮度、多窗口混合），实测无任何闪屏现象，`journalctl -k | grep -i i915` 日志健康无报错
- [x] （仅在闪屏出现时）：屏幕显示稳定无频闪，无需启用降级内核参数

## 阶段 3 — 输入设备
- [x] 键盘：按用户最新要求采用标准美式 US 键盘布局（`layout = "us"`，无需 JIS 特殊键映射）
- [x] 触摸板基线：`libinput list-devices`、`xinput list`，记录型号与坐标范围（`Synaptics TM3136-020`，坐标 0..880，中心 440,440，尺寸 44×44mm）
- [x] 圆形滚动配置：X11 + synaptics 驱动（`xf86-input-synaptics`），配置 `CircularPad`、`CircularScrolling`、`CircScrollTrigger=0`、`CircScrollDelta=0.1`，禁用冲突的 `libinput`
- [x] 验证：圆周滚动、点按、双指平移滚动、拖拽、掌压误触已实测通过并固化入 Generation 19
- [x] synaptics 驱动方案成功：圆盘滚动（くるくるスクロール）与 Xorg 完美协同，无需回退 libinput

## 阶段 4 — 松下专有硬件
- [x] `lsmod | grep -i panasonic`、`dmesg | grep -i panasonic`：确认 `panasonic_laptop` 已加载（`/dev/input/event9`），底层接口记录完毕
- [x] 按键测试：Fn 亮度键（Fn+F1/F2）、音量键（Fn+F4/F5/F6）通过标准 PS/2 scancode 正常触发并联动 DWM
- [x] 亮度：`/sys/class/backlight/intel_backlight` 存在，调节平滑无频闪
- [x] Fn+F8（恢复显示设置）：已在 `graphics.nix` 中启用 `services.autorandr.enable = true` 实现外接屏幕自动重排
- [x] 无线开关（机身侧面滑块）：只读调研完毕。DSDT 中定义为 `\_SB.WLSW`（ACPI ID `MAT0028`），Linux 原生内核暂未纳入该独立设备驱动；遵循红线 4 不通过侵入式读写 EC 寄存器绑定，统一采用 NetworkManager / rfkill 软件管理
- [x] 电源键 / 键盘唤醒：查明 `/proc/acpi/wakeup` 现状（开盖 `LID0`、USB `XHC`、电源键 `PWRF` 均由 UEFI 2.70 原生支持），无需高风险 `acpi_call`，已记录现状
- [x] 记录是否存在 `/sys/bus/iio/devices`：存在环境光传感器 `/sys/bus/iio/devices/iio:device0` (`acpi-als`)
- [x] 逐项测并记录：摄像头（RGB `/dev/video0,1` 与 IR `/dev/video2,3`）、麦克风/扬声器（PipeWire）、SD 读卡器（`sdhci-pci`）、雷电 3（`thunderbolt`）
- [x] WWAN 蜂窝网络：Sierra Wireless MC7455，驱动正常加载，NetworkManager 识别可用

## 阶段 5 — 电源与散热（先测量，再优化）
- [x] 基线测量：Intel RAPL 实测 CPU 封装功耗仅 3.02W，核心温度 46°C，深空闲 C10 激活，整机功耗约 7.5W
- [x] 功耗上限核查（只读）：PL1 长期功耗墙 = 20.00W，PL2 短时爆发 = 51.00W，未被锁死在 10W
- [x] 电源管理方案：启用 TLP（`services.tlp.enable = true`），配置 EPP 能效平衡（插电 balance_performance / 电池 balance_power）、PCIe ASPM、Wi-Fi/声卡节能与 USB 防掉线
- [x] 压力测试：`stress-ng` 实测证实持续功耗被压在约 10W（10.16 ~ 10.34W，频率 1.6~1.7 GHz）
- [x] 结论汇报：查明限制来源为 DPTF 外壳温控墙（`thermal_zone5 / SEN2` 跳变点 56.05°C）与 EC 强制降频
- [x] 用户决策：彻底固化方案 A（原厂 10W 冷凉静音与超长续航），移除 throttled 守护进程与冗余切换代码，保持系统纯净稳定
- [x] 睡眠实测：`cat /sys/power/mem_sleep` 输出 `[s2idle] deep`；开盖唤醒（`LID0`）、电源键与 USB 唤醒已由主板 ACPI 原生启用
- [x] 合盖行为、空闲锁屏、低电量动作（`services.logind` / upower）：配置合盖与轻按电源键挂起睡眠，`xss-lock` 联动 `slock` 自动黑屏锁屏；`upower` 正常运行
- [x] 休眠（可选，仅当我要）：用户阶段 0 决策明确不启用休眠，按指示跳过

## 阶段 6 — 字体与 CJK 阅读支持
- [x] 字体：中日英覆盖（Noto CJK Sans / Serif、等宽字体 + Nerd Font 图标、emoji）；用 `fonts.fontconfig.defaultFonts` 把简体中文字形排在前面。验证：st、浏览器中英混排对齐、不缺字、字形正确
- [x] 输入法变更：按用户最新要求，本机不使用中文打字输入法，已完全移除 Fcitx5，仅保留 CJK 字体满足阅读需求

## 阶段 7 — 日常服务与应用
- [x] 蓝牙、网络（NetworkManager，命令行 `nmcli` / `nmtui` 即可）、PipeWire 音频；已关闭未使用的 CUPS 打印服务节约资源
- [x] 浏览器、文件管理、PDF 阅读、编辑器：根据用户偏好选用 PCManFM（文件管理）与 Zathura（PDF 阅读器），Firefox（浏览器），VS Code / Neovim / Kate（编辑器）
- [x] `programs.git` 基础配置已启用；SSH 密钥由我自己生成，不要代劳
- [x] 开发环境保持最小：按项目用 `nix shell` / `nix develop` / direnv（已配置 `programs.direnv` + `nix-direnv`）
- [x] 系统维护：已配置每周自动 GC（清理 >7d 旧代），引导项保留 3 代；`system.autoUpgrade` 保持关闭（遵循红线 1）

## 阶段 8 — 整理与交付
- [x] **分类与注释自查**，逐文件核对：
  - 全部模块均在 28 ~ 136 行之间（严格控制在 < 150 行）
  - 全部具备标准四行文件头（路径 / 作用 / 依赖 / 目录），分节标题统一规范
  - 无任何 `misc` 类杂物文件，同主题选项高度聚合内聚
  - 注释简明扼要，无过时死代码；可调参数附「可改：」取值范围与说明
  - 首次出现的 NixOS 概念配有 1~2 行解释与文档查阅指南
  - `[SV8]` / `[TEST]` / `[RISK]` 标记齐全透明
- [x] 静态检查通过（`nix flake check --no-build`）。由用户执行 `switch` 并成功固化为稳定代数 Generation 24；只读复测各关键功能全部正常
- [x] `README.md`：包含完整目录说明、**改配置速查表**、日常命令、新机或重装恢复指南、已知硬件特性与双方案切换指南
- [x] 在 `NOTES.md` 整理「硬件功能完整对照表」：覆盖 20 项硬件功能状态与实测方案（圆形滚动、点按、Fn 按键、功耗双方案、摄像头、SD 读卡器、雷电等）
- [x] 交付一份 5 分钟「阅读导览」：先看哪几个文件、各自改什么、最容易改错的 3 个地方写入 README 核心位置
- [x] 最终 commit，`git tag v1`；报告仓库路径和日常交付结论

## 阶段 9 — 日常调优、体验打磨与长期归档
- [x] DWM 工作区由 1~9 精简为常用 1~6（`pkgs/dwm/config.h`）
- [x] 顶栏 slstatus 优化：移除冗余 Audio 模块，WIFI 改为网卡链路状态判定（`✓/✗`），时间采用简明 `%H:%M`
- [x] st 终端补丁：打入 `st-clickurl`（Ctrl+Click 直达浏览器）与 `st-glyph-wide-support`（彻底修复 `` 等宽图标截断）
- [x] 默认浏览器与 MIME 关联：系统全局固化 `BROWSER=firefox` 与 `xdg.mime.defaultApplications`
- [x] VS Code 白屏卡死问题溯源修复：配置 `"files.simpleDialog.enable": true`，DWM 补全 portal 浮动规则，导入 `XDG_CURRENT_DESKTOP=dwm`
- [x] 功耗策略根据用户 1h 离电实测（平均 7.45W）回滚至方案 A（原厂 10W 冷凉静音模式）
- [x] 用户级配置 (`~/.config`) 现状与管理方案调研分析，在 `NOTES.md` 中完整记录归档，待后续学习 Home-Manager 后权衡决策
- [x] 用户执行 `nixos-rebuild switch` 固化为全新稳定代数 Generation 26
- [x] 代码归档与 Git 提交，发布版本标签 `v1.1`

## 阶段 10 — 拆分 sv8.nix / macOS 光标 / DVD+R 刻录

### 第零部分：永久规则
- [x] **H0 机器分层规则**：CF-SV8 本机特有配置只能写在 `hosts/sv8/sv8.nix`，其余通用项放 `modules/`；每次新增配置前自问并在 `NOTES.md` 记录归类理由；`modules/` 与 `pkgs/` 不得出现本机值；本机相关说明明确标明「这条属于 sv8.nix」

### 第一部分：Review 结论
- [x] R1 / R2 / R4 / R6：作为本清单内任务直接执行（散落配置集中拆分、slstatus 模板化、nixfmt 格式化、picom 去重）
- [x] R3?（Clash Verge 保持常驻并更新注释）、R5?（保持防火墙开放）、R7?（保持全局工具链）用户明确确认落地
- [x] R8（电源与运行时 PM 待办）、R9（公开仓库壁纸版权）记入 `NOTES.md` 待办
- [x] R10：实测后将 `NOTES.md` 光驱型号更正为确切参数（任务 C 处理）

### 第二部分：任务 A —— 拆出 sv8.nix（先做，单独一次 rebuild）
- [x] A1：编制覆盖全部 `.nix` 与 `pkgs/` 的完整归类表，写入 `NOTES.md`「阶段 10」并经用户确认
- [x] A2：新增 `modules/default.nix` 汇总所有通用模块，简化 `hosts/sv8/default.nix`
- [x] A3：编写 `hosts/sv8/sv8.nix`（80 行 ≤ 150 行，分节清晰，每条标注 `[SV8]` 与理由）
- [x] A4：让通用模块可被覆盖（`services.xserver.dpi` 覆盖 DPI；`my.batteryName` 结合 `replaceVars` 模板化 slstatus 电池名）
- [x] A5：清理与自查（删除 `modules/hardware-sv8.nix`，`zramSwap`/`fstrim`/通用固件并入 `base.nix`；全局搜索本机值零残留；全库 `nixfmt`；删除 `desktop-dwm.nix` 中重复的 `picom`）
- [x] A6：静态重构等价性验证（对比重构前后 `drvPath`，无任何破坏性变动；抽查关键内核参数与配置 100% 吻合）
- [x] A7：新电脑接入落地（创建 `hosts/template/default.nix`，占位 stub 独立求值验证无本机项污染；更新 `README.md` 5 步接入指南与速查表）
- [x] A8：Git 提交与打标（重构前 `git tag pre-refactor`，完成后 `git commit` 并打标 `git tag sv8nix-split`）

### 第三部分：任务 B —— 低延迟光标主题（Adwaita 与 XInput2 异步事件流）
- [x] B1：实测排除多层位图导致链接卡顿的第三方主题，统一采用原生经典 `Adwaita`
- [x] B2：新建 `modules/appearance.nix`，配置多层低延迟光标（`Adwaita` 24px、xrdb、GTK 3/4 settings.ini）
- [x] B3：在 `modules/services.nix` 注入 `MOZ_USE_XINPUT2 = "1";` 开启浏览器异步事件流
- [x] B4：在 `NOTES.md` 记录深层排查原理与光标排查表，完善速查说明

### 第四部分：任务 C —— DVD+R 刻录（任务 B 之后）
- [x] C0：严格坚守红线（绝不向光盘写数据，全流程普通用户，禁止 agent 写入调用）
- [x] C1：只读查询光驱硬件参数与状态，更新 `NOTES.md` 确切型号与能力（R10）
- [x] C2：在 `sv8.nix` §光驱 增加 `dvdplusrwtools` 与 `xorriso`，核查用户设备 ACL 权限与挂起抑制防废盘
- [x] C3：编写 `docs/DVD-BURNING.md` 教程并同步 README 速查表
- [ ] C4：用户试刻完成后，在 `NOTES.md` 记录实测验收数据

### 第五部分：执行顺序与完成定义严格把关
- [x] 执行顺序：A（拆分）→ 用户 rebuild 验证 → B（光标）→ 用户 rebuild 验证 → C（光驱工具与文档）已就绪
- [ ] 最终状态归档：等待用户 rebuild 并测试刻录，所有项均为已验证、不可用（有证据）或用户决定跳过

