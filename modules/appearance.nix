# modules/appearance.nix — 全局桌面外观与光标主题定制
# 包含：macOS 风格光标主题 (apple-cursor)、X11/XRDB、全局环境变量与 GTK 3/4 样式统一
{
  config,
  lib,
  pkgs,
  ...
}:

let
  # 光标主题名称（由 apple-cursor 包提供）
  # 可选："macOS"（经典黑色，默认推荐）或 "macOS-White"（白色高对比度）
  cursorTheme = "macOS";

  # 光标像素尺寸（可改：24 / 28 / 32 / 40 / 48）
  # 算法推导：基础 24px * 缩放倍率 (144/96 = 1.5x) 为 36px，选取主题支持的最佳预渲染物理尺寸 32px
  cursorSize =
    let
      targetDpi = if config.services.xserver.dpi != null then config.services.xserver.dpi else 96;
    in
    if targetDpi >= 192 then
      48
    else if targetDpi >= 144 then
      32
    else if targetDpi >= 120 then
      28
    else
      24;
in
{
  # ── 1. 光标主题软件包与系统图标资源链接 ─────────
  # 安装开源 macOS 风格光标 (ful1e5/apple_cursor)
  environment.systemPackages = with pkgs; [
    apple-cursor
  ];

  # 确保 X11 / 图标主题目录自动符号链接至 /run/current-system/sw/share/icons
  environment.pathsToLink = [ "/share/icons" ];

  # ── 2. 全局环境变量 (XCURSOR_*) ─────────────────
  # XCURSOR_* 是 X11 客户端（包括 Alacritty、VS Code/Electron、Qt 等）读取光标的标准环境变量
  environment.variables = {
    XCURSOR_THEME = cursorTheme;
    XCURSOR_SIZE = toString cursorSize;
  };

  # ── 3. X11 资源数据库 (Xresources / xrdb) ────────
  # xrdb 将光标主题写入 X11 根窗口属性数据库，供原生 Xlib/XCB 客户端以及 xsetroot 读取
  services.xserver.displayManager.startx.extraCommands = ''
    # Xcursor 资源合并至 X 资源数据库
    ${pkgs.xrdb}/bin/xrdb -merge <<'EOF'
    Xcursor.theme: ${cursorTheme}
    Xcursor.size: ${toString cursorSize}
    EOF
  '';

  # ── 4. GTK 3.0 / GTK 4.0 系统级外观配置 ─────────
  # 供基于 GTK 的图形程序（Firefox、PCManFM、Clash Verge 等）读取默认光标样式
  environment.etc."xdg/gtk-3.0/settings.ini".text = ''
    [Settings]
    gtk-cursor-theme-name=${cursorTheme}
    gtk-cursor-theme-size=${toString cursorSize}
  '';

  environment.etc."xdg/gtk-4.0/settings.ini".text = ''
    [Settings]
    gtk-cursor-theme-name=${cursorTheme}
    gtk-cursor-theme-size=${toString cursorSize}
  '';
}
