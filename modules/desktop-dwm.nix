# modules/desktop-dwm.nix — X11 与 DWM 极简平铺桌面
# 作用：X11 服务、DWM 窗口管理器定制、Suckless 工具链、状态栏与锁屏
# 依赖：pkgs/dwm/config.h, pkgs/st/config.h, pkgs/dmenu/config.h, pkgs/slstatus/config.h, pkgs/st/patches/*
# 目录：1. 显示与 DPI 设置  2. TTY 自动登录与 startx  3. DWM 窗口管理器  4. 桌面合成与套件
{
  config,
  pkgs,
  ...
}:

let
  # 12.1 英寸 1920x1200 屏幕 DPI。放大至 144 (1.5x 缩放)，字体更清晰省力
  # 可改：96 (1.0x), 120 (1.25x), 144 (1.5x), 168 (1.75x)
  targetDpi = 144;

  # 定制编译的 Suckless 核心工具链
  customDwm = pkgs.dwm.override {
    conf = ../pkgs/dwm/config.h;
  };
  customSt = pkgs.st.override {
    patches = [
      ../pkgs/st/patches/st-scrollback-0.9.2.diff
      ../pkgs/st/patches/st-scrollback-mouse-0.9.2.diff
      ../pkgs/st/patches/st-scrollback-mouse-altscreen-20220127-2c5edf2.diff
    ];
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
      # 合并 X 资源配置（统一设置全局 144 DPI）
      echo "Xft.dpi: ${toString targetDpi}" | ${pkgs.xrdb}/bin/xrdb -merge -

      # 设置鼠标默认指针形状（left_ptr）
      ${pkgs.xsetroot}/bin/xsetroot -cursor_name left_ptr &

      # 设定桌面壁纸（使用 ~/Pictures 下唯一的 Kurisu.png）
      if [ -f /home/flynn/Pictures/Kurisu.png ]; then
        ${pkgs.feh}/bin/feh --bg-fill /home/flynn/Pictures/Kurisu.png &
      else
        ${pkgs.xsetroot}/bin/xsetroot -solid "#1e1e2e" &
      fi

      # 启动轻量合成器 picom，实现终端 80% (0.8) 半透明与硬件加速防撕裂
      ${pkgs.picom}/bin/picom -b --backend glx --vsync \
        --opacity-rule "80:class_g = 'st-256color'" \
        --opacity-rule "80:class_g = 'st'" \
        --opacity-rule "80:class_g = 'Alacritty'" &

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

  # ── 4. 桌面合成与核心套件 ────────────────────
  # 声明式配置 picom 合成器服务，提供窗口不透明度与渲染后端
  services.picom = {
    enable = true;
    backend = "glx";
    vSync = true;
    opacityRules = [
      "80:class_g = 'st-256color'"
      "80:class_g = 'st'"
      "80:class_g = 'Alacritty'"
    ];
  };

  # 开启 slock setuid 权限包装器，使锁屏支持验证 shadow 用户密码
  programs.slock.enable = true;

  environment.systemPackages = with pkgs; [
    customSt # 极简终端模拟器（已包含回滚缓冲与鼠标滚轮补丁）
    customDmenu # 极简应用启动菜单（已放大字体）
    customSlstatus # 极简状态栏
    picom # X11 合成器
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
