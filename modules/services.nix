# modules/services.nix — 系统服务与应用软件
# 包含：网络管理、蓝牙、PipeWire 音频、Clash Verge 代理与日常应用
{ pkgs, lib, ... }:

{
  # ── 1. 网络与蓝牙 ────────────────────────────
  networking.networkmanager.enable = true;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true; # 开机默认开启适配器供电
  };

  # ── 2. 音频子系统 ────────────────────────────
  services.pulseaudio.enable = false;
  security.rtkit.enable = true; # 授予音频线程实时调度权限，防止爆音
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # ── 3. 硬件固件检测 ──────────────────────────
  services.fwupd.enable = true; # 用于只读检查固件更新 (fwupdmgr get-updates)

  # ── 4. 存储、桌面 Portal 与应用集成 ──────────
  services.printing.enable = false;
  services.flatpak.enable = false;

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "gtk";
  };

  services.udisks2.enable = true; # 存储设备管理守护进程

  programs.firefox.enable = true;

  # 统一默认浏览器关联至 Firefox
  xdg.mime.defaultApplications = {
    "text/html" = "firefox.desktop";
    "x-scheme-handler/http" = "firefox.desktop";
    "x-scheme-handler/https" = "firefox.desktop";
    "x-scheme-handler/about" = "firefox.desktop";
    "x-scheme-handler/unknown" = "firefox.desktop";
  };

  environment.sessionVariables = {
    BROWSER = "firefox";
    TERMINAL = "alacritty";
    MOZ_USE_XINPUT2 = "1"; # 启用 XInput2 高精度事件流，彻底消除浏览器中鼠标划过超链接时的事件阻塞与阻滞感
  };

  # 局域网跨设备互传工具
  programs.localsend = {
    enable = true;
    openFirewall = true;
  };

  # ── 5. 网络代理 (Clash Verge Rev，常驻系统代理服务) ────────
  # 以 root systemd 服务模式安全托管 TUN 模式与透明代理
  # programs.clash-verge = {
  #  enable = true;
  #  package = pkgs.symlinkJoin {
  #    name = "clash-verge-rev";
  #    paths = [ pkgs.clash-verge-rev ];
  #    nativeBuildInputs = [ pkgs.makeWrapper ];
  #    postBuild = ''
  #      wrapProgram $out/bin/clash-verge \
  #        --set WEBKIT_DISABLE_DMABUF_RENDERER 1
  #    '';
  #  };
  #  tunMode = false; # 禁用 GUI setcap 包装，避免触发 AT_SECURE 导致 WebKitGTK 沙盒白屏
  #  serviceMode = true; # 由 root systemd 服务安全托管 TUN 模式
  # };

  # 允许普通用户态 GUI 访问后台守护进程的套接字通信
  # systemd.services.clash-verge.serviceConfig.PrivateTmp = lib.mkForce false;

  # ── 6. 日常桌面套件 ──────────────────────────
  environment.systemPackages = with pkgs; [
    pcmanfm # 轻量图形文件管理器
    zathura # 极简 Vim 键位平铺 PDF 阅读器
    newsflash # RSS 阅读器
    mpv # 轻量多媒体播放器
    ayugram-desktop # Telegram 增强型桌面客户端
    anki # 记忆卡片学习软件
    qbittorrent-enhanced # 增强版 BT 下载客户端
  ];
}
