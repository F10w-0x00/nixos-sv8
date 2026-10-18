# modules/desktop-dwm.nix — X11 与 DWM 极简平铺桌面
# 作用：X11 服务、DWM 窗口管理器定制、Suckless 工具链、状态栏与锁屏
# 依赖：pkgs/dwm/config.h, pkgs/st/config.h, pkgs/dmenu/config.h, pkgs/slstatus/config.h
# 目录：1. 显示与 DPI 设置  2. TTY 自动登录与 startx  3. DWM 窗口管理器  4. 桌面核心套件
{
  config,
  pkgs,
  ...
}:

let
  # 12.1 英寸 1920x1200 屏幕 DPI。可改：96 (1.0x), 120 (1.25x), 144 (1.5x)
  targetDpi = 120;

  # 定制编译的 Suckless 核心工具链
  customDwm = pkgs.dwm.override {
    conf = ../pkgs/dwm/config.h;
  };
  customSt = pkgs.st.override {
    conf = builtins.readFile ../pkgs/st/config.h;
  };
  customDmenu = pkgs.dmenu.override {
    conf = ../pkgs/dmenu/config.h;
  };
  customSlstatus = pkgs.slstatus.override {
    conf = ../pkgs/slstatus/config.h;
  };
in
{
  # ── 1. 显示与 DPI 设置 ────────────────────────
  services.xserver = {
    enable = true;
    dpi = targetDpi;
  };

  # ── 2. TTY 自动登录与 startx ────────────────
  # 关闭 SDDM 与 Plasma 6，切换至极简轻量级 tty 自动登录 + startx
  services.displayManager.sddm.enable = false;
  services.desktopManager.plasma6.enable = false;

  # 控制台 tty1 免密码自动登录
  services.getty.autologinUser = "flynn";

  # 仅在 tty1 登录且无图形会话时自动执行 startx，其他 tty 保持字符终端排障
  environment.loginShellInit = ''
    if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
      exec startx
    fi
  '';

  # 配置 startx 伪显示管理器及全局会话启动脚本
  services.xserver.displayManager.startx = {
    enable = true;
    generateScript = true;
    extraCommands = ''
      # 合并 X 资源配置（统一设置全局 120 DPI）
      echo "Xft.dpi: ${toString targetDpi}" | ${pkgs.xrdb}/bin/xrdb -merge -

      # 设置鼠标默认指针形状（left_ptr）并填充纯深色背景
      ${pkgs.xsetroot}/bin/xsetroot -cursor_name left_ptr -solid "#1e1e2e" &

      # 启动 Fcitx5 输入法守护进程
      ${pkgs.fcitx5}/bin/fcitx5 -d &

      # 启动桌面通知服务
      ${pkgs.dunst}/bin/dunst &

      # 启动睡眠/空闲自动锁屏监听器（合盖与超时自动唤起 slock）
      ${pkgs.xss-lock}/bin/xss-lock --transfer-sleep-lock -- ${pkgs.slock}/bin/slock &

      # 启动 U 盘自动挂载守护进程
      ${pkgs.udiskie}/bin/udiskie --no-notify &

      # 启动顶部状态栏（展示 CPU、内存、Wi-Fi、电量、时钟）
      ${customSlstatus}/bin/slstatus &
    '';
  };

  # ── 3. DWM 窗口管理器 ────────────────────────
  # 首次出现的概念：NixOS 声明式替换源码配置（override { conf = ...; }）
  # 注意：dwm 绝不可放入 environment.systemPackages，否则 override 无法生效
  services.xserver.windowManager.dwm = {
    enable = true;
    package = customDwm;
  };

  # ── 4. 桌面核心套件 ──────────────────────────
  # 开启 slock setuid 权限包装器，使锁屏支持验证 shadow 用户密码
  programs.slock.enable = true;

  environment.systemPackages = with pkgs; [
    customSt # 极简终端模拟器（已定制 JetBrainsMono Nerd Font）
    customDmenu # 极简应用启动菜单
    customSlstatus # 极简状态栏
    brightnessctl # 屏幕背光亮度控制工具
    maim # 屏幕截图工具
    xclip # X11 剪贴板交互工具
    feh # 壁纸设置与轻量图像查看器
    dunst # 轻量级桌面通知服务
    libnotify # notify-send 命令行通知发送工具
    xss-lock # X 屏幕保护与休眠自动锁屏联动
    udiskie # 可移动磁盘自动挂载前端
    xsetroot # X11 根窗口设置（鼠标指针、纯色背景）
    xrdb # X 资源数据库管理
    xev # X11 键盘按键事件测试工具（排查 Fn 键）
  ];
}
