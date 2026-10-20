# modules/services.nix — 系统服务与日常应用
# 作用：网络管理、蓝牙、PipeWire 音频、fwupd 固件检测、日常常驻工具
# 依赖：无
# 目录：1. 网络与蓝牙  2. 音频子系统  3. 固件检测 (fwupd)  4. 存储、桌面支持与日常应用
{ pkgs, lib, ... }:

{
  # ── 1. 网络与蓝牙 ────────────────────────────
  networking.networkmanager.enable = true; # 使用 NetworkManager 管理 Wi-Fi 与有线网

  # [SV8] 启用机载 Intel 9560 蓝牙模块（ID 8087:0aaa）
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true; # 开机默认开启蓝牙适配器供电
  };

  # ── 2. 音频子系统 ────────────────────────────
  # 使用现代 PipeWire 替代旧版 PulseAudio，兼具低延迟与对 ALSA/Pulse 的完整兼容
  services.pulseaudio.enable = false;
  security.rtkit.enable = true; # 赋予音频线程实时调度权限，防止爆音
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # ── 3. 固件检测 (fwupd) ──────────────────────
  # [SV8] 仅用于只读检查固件更新信息（fwupdmgr get-updates），红线规则严禁自动刷固件
  services.fwupd.enable = true;

  # ── 4. 存储、桌面支持与日常应用 ──────────────
  services.printing.enable = false; # 不需要打印服务保持关闭，节约内存与启动耗时
  services.flatpak.enable = false; # 关闭 Flatpak 跨发行版软件包支持，节约空间与服务开销
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "gtk";
  };
  services.udisks2.enable = true; # UDisks2 存储设备管理服务（供 udiskie 自动挂载）

  programs.firefox.enable = true; # 常用网页浏览器

  # 默认应用与 MIME 关联：将网页链接与 HTML 文件统一关联至 Firefox
  xdg.mime.defaultApplications = {
    "text/html" = "firefox.desktop";
    "x-scheme-handler/http" = "firefox.desktop";
    "x-scheme-handler/https" = "firefox.desktop";
    "x-scheme-handler/about" = "firefox.desktop";
    "x-scheme-handler/unknown" = "firefox.desktop";
  };

  # 全局默认浏览器环境变量
  environment.sessionVariables = {
    BROWSER = "firefox";
  };

  # 局域网跨设备互传工具
  programs.localsend = {
    enable = true;
    openFirewall = true; # 自动在防火墙中放行 LocalSend 所需端口
  };

  # 代理网络工具（Clash Verge Rev，Mihomo 内核）
  programs.clash-verge = {
    enable = true;
    package = pkgs.symlinkJoin {
      name = "clash-verge-rev";
      paths = [ pkgs.clash-verge-rev ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/clash-verge \
          --set WEBKIT_DISABLE_DMABUF_RENDERER 1
      '';
    };
    tunMode = false; # 禁用 setcap 包装：serviceMode 已由 root systemd 托管，开启 tunMode 会给 GUI 加 setcap 触发 AT_SECURE 导致 WebKitGTK 沙盒白屏
    serviceMode = true;
  };

  # 修复 nixpkgs clash-verge-service 的 PrivateTmp 导致普通用户 GUI 无法访问 unix socket 的缺陷
  systemd.services.clash-verge.serviceConfig.PrivateTmp = lib.mkForce false;

  # 游戏分发平台（开启 Steam 官方包装，自动配置 32 位 OpenGL/Vulkan 库与 FHS 环境）
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # 局域网流式传输放行端口
  };

  environment.systemPackages = with pkgs; [
    pcmanfm # [阶段 7 选型] 轻量级图形文件管理器，极速、与 DWM 契合
    zathura # [阶段 7 选型] 极简 Vim 键位平铺 PDF 阅读器
    piliplus # Bilibili 第三方客户端
    newsflash # 现代化 RSS 阅读器
    mpv # 轻量级多媒体播放器
    ayugram-desktop # Telegram 增强型第三方桌面客户端（支持防撤回与幽灵模式）
    anki # 间隔重复记忆卡片学习软件 (Anki)
    qbittorrent-enhanced # 支持自动屏蔽吸血客户端的增强版 BT 下载器 (qBittorrent-EE)
  ];
}
