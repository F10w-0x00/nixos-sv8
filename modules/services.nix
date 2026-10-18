# modules/services.nix — 系统服务与日常应用
# 作用：网络管理、蓝牙、PipeWire 音频、fwupd 固件检测、日常常驻工具
# 依赖：无
# 目录：1. 网络与蓝牙  2. 音频子系统  3. 固件检测 (fwupd)  4. 打印与日常应用
{ pkgs, ... }:

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

  # ── 4. 打印与日常应用 ────────────────────────
  services.printing.enable = true; # CUPS 打印服务
  services.flatpak.enable = true; # Flatpak 跨发行版软件包支持

  programs.firefox.enable = true; # 常用网页浏览器

  # 局域网跨设备互传工具
  programs.localsend = {
    enable = true;
    openFirewall = true; # 自动在防火墙中放行 LocalSend 所需端口
  };

  # 代理网络工具（Clash Verge Rev，Mihomo 内核）
  programs.clash-verge = {
    enable = true;
    package = pkgs.clash-verge-rev;
    tunMode = true;
    serviceMode = true;
  };

  environment.systemPackages = with pkgs; [
    piliplus # Bilibili 第三方客户端
    newsflash # 现代化 RSS 阅读器
    mpv # 轻量级多媒体播放器
    spotify # 音乐流媒体客户端
  ];
}
