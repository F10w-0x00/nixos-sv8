# modules/appearance.nix — 全局桌面外观与光标主题定制
# 包含：原生低延迟 Adwaita 光标主题、X11/XRDB、全局环境变量与 GTK 3/4 样式统一
{
  config,
  lib,
  pkgs,
  ...
}:

let
  # 经典轻量原生低延迟光标主题（Adwaita）
  # 彻底杜绝第三方大尺寸光标在链接切换时的位图解码开销与热点突变阻滞感
  cursorTheme = "Adwaita";

  # 标准物理光标尺寸（24px，热点精准，零渲染负担）
  cursorSize = 24;
in
{
  # ── 1. 光标主题软件包与系统图标资源链接 ─────────
  environment.systemPackages = with pkgs; [
    adwaita-icon-theme
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
