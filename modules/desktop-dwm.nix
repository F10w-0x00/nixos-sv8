# modules/desktop-dwm.nix — X11 与 DWM 极简平铺桌面环境
# 包含：DWM 窗口管理器源码定制、Suckless 核心工具链、状态栏、锁屏与终端
{
  config,
  lib,
  pkgs,
  ...
}:

let
  # 屏幕 DPI（优先读取主机层设定，未设定时安全回落至标准 96 DPI）
  targetDpi = if config.services.xserver.dpi != null then config.services.xserver.dpi else 96;

  # 桌面壁纸（自包含于仓库 wallpapers/ 目录下，随构建打包进系统）
  wallpaperPath = ../wallpapers/wallpaper.png;

  # Suckless 工具链定制编译注入
  customDwm = pkgs.dwm.override {
    conf = ../pkgs/dwm/config.h;
  };
  customDmenu = pkgs.dmenu.override {
    conf = ../pkgs/dmenu/config.h;
  };
  customSlstatus = pkgs.slstatus.override {
    conf = pkgs.replaceVars ../pkgs/slstatus/config.h.in {
      batteryName = config.my.batteryName;
    };
  };
in
{
  # ── 自定义通用配置选项 ───────────────────────
  options.my = {
    batteryName = lib.mkOption {
      type = lib.types.str;
      default = "BAT0";
      description = "电池设备名称，用于 slstatus 状态栏显示";
    };
  };

  config = {
    # ── 1. 显示与 DPI 设置 ────────────────────────
    services.xserver = {
      enable = true;
      dpi = lib.mkDefault 96;
    };

    # ── 2. TTY 自动登录与 startx ────────────────
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

        # 设定全局渲染 DPI
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

    # ── 4. 桌面配套工具 ──────────────────────────
    # 仅负责 VSync 垂直同步的极简 picom 合成器：
    # 彻底杜绝网页与 PDF 快速滑动时的画面撕裂（Screen Tearing）
    # 彻底关闭所有阴影、渐变淡入淡出、窗口透明与毛玻璃等重度特效，保持零视觉延迟与最低功耗
    services.picom = {
      enable = true;
      backend = "glx"; # 采用 OpenGL 硬件渲染后端（Intel UHD 620 核显成熟稳定）
      vSync = true; # 强制锁死 60Hz 垂直同步，根除滚动撕裂
      shadow = false; # 彻底禁用窗口阴影
      fade = false; # 彻底禁用窗口淡入淡出动画
      activeOpacity = 1.0;
      inactiveOpacity = 1.0;
      settings = {
        # 增量渲染优化：仅在屏幕区域发生像素变化时重绘对应区域，杜绝全屏无谓刷新
        use-damage = true;
        # 全屏应用/视频播放时自动解除重定向（直通渲染），杜绝输入延迟
        unredir-if-possible = true;
      };
    };

    programs.slock.enable = true; # 开启 setuid 权限支持校验用户密码

    environment.systemPackages = with pkgs; [
      customDmenu # dmenu 应用启动器
      customSlstatus # slstatus 状态栏
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
  };
}
