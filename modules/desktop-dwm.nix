# modules/desktop-dwm.nix — X11 与 DWM 极简平铺桌面环境
# 包含：DWM 窗口管理器源码定制、Suckless 核心工具链、状态栏、锁屏与终端
{
  config,
  pkgs,
  ...
}:

let
  # 12.1 英寸 1920x1200 屏幕 DPI（144 对应 1.5x 视觉缩放，字迹清晰锐利）
  targetDpi = 144;

  # 桌面壁纸（自包含于仓库 wallpapers/ 目录下，随构建打包进系统）
  wallpaperPath = ../wallpapers/wallpaper.png;

  # Suckless 工具链定制编译注入
  customDwm = pkgs.dwm.override {
    conf = ../pkgs/dwm/config.h;
  };
  customSt = pkgs.st.override {
    patches = [
      ../pkgs/st/patches/st-scrollback-0.9.2.diff
      ../pkgs/st/patches/st-scrollback-mouse-0.9.2.diff
      ../pkgs/st/patches/st-scrollback-mouse-altscreen-20220127-2c5edf2.diff
      ../pkgs/st/patches/st-glyph-wide-support-20220411-ef05519.diff
      ../pkgs/st/patches/st-clickurl-0.9.3.diff
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
  services.displayManager.sddm.enable = false;
  services.desktopManager.plasma6.enable = false;

  # tty1 免密码自动登录
  services.getty.autologinUser = "flynn";

  # 登录 tty1 时自动启动 X11 会话，其余 tty 保持纯终端用于排障
  environment.loginShellInit = ''
    if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
      exec startx
    fi
  '';

  # 会话环境初始化脚本
  services.xserver.displayManager.startx = {
    enable = true;
    generateScript = true;
    extraCommands = ''
      # 导出环境变量给 systemd 用户服务与 D-Bus
      export XDG_CURRENT_DESKTOP=dwm
      systemctl --user import-environment DISPLAY XAUTHORITY XDG_CURRENT_DESKTOP
      ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd DISPLAY XAUTHORITY XDG_CURRENT_DESKTOP

      # 设定全局 144 DPI
      echo "Xft.dpi: ${toString targetDpi}" | ${pkgs.xrdb}/bin/xrdb -merge -

      # 默认光标形状
      ${pkgs.xsetroot}/bin/xsetroot -cursor_name left_ptr &

      # 加载自包含壁纸
      ${pkgs.feh}/bin/feh --bg-fill ${wallpaperPath} &

      # 桌面通知守护进程
      ${pkgs.dunst}/bin/dunst &

      # 空闲与休眠自动锁屏联动 (slock)
      ${pkgs.xss-lock}/bin/xss-lock --transfer-sleep-lock -- ${pkgs.slock}/bin/slock &

      # 可移动存储设备自动挂载
      ${pkgs.udiskie}/bin/udiskie --no-notify &

      # 启动顶部状态栏
      ${customSlstatus}/bin/slstatus &
    '';
  };

  # ── 3. DWM 窗口管理器 ────────────────────────
  services.xserver.windowManager.dwm = {
    enable = true;
    package = customDwm;
  };

  # ── 4. 桌面合成与配套工具 ────────────────────
  services.picom = {
    enable = true;
    backend = "glx";
    vSync = true;
  };

  programs.slock.enable = true; # 开启 setuid 权限支持校验用户密码

  environment.systemPackages = with pkgs; [
    customSt # st 极简终端（集成回滚、宽字符、URL 点击补丁）
    customDmenu # dmenu 应用启动器
    customSlstatus # slstatus 状态栏
    picom # X11 合成器
    brightnessctl # 屏幕背光调节工具
    maim # 屏幕截图工具
    xclip # 剪贴板管理工具
    feh # 壁纸加载与看图工具
    dunst # 桌面通知服务
    libnotify # notify-send 工具
    xss-lock # 自动锁屏联动
    udiskie # 存储设备自动挂载
    xsetroot # X 根窗口管理
    xrdb # X 资源数据库配置
    xev # 按键测试工具
  ];
}
