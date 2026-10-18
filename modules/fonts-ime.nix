# modules/fonts-ime.nix — 字体与中文输入法
# 作用：中日英字体配置、Fontconfig 回退优先级、Fcitx5 中文输入法
# 依赖：无
# 目录：1. 字体包与 Fontconfig 默认值  2. Fcitx5 输入法
{ pkgs, ... }:

{
  # ── 1. 字体包与 Fontconfig 默认值 ────────────
  fonts = {
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono # 英文与等宽 Nerd Font 图标字体
      noto-fonts-cjk-sans # Google Noto 黑体（覆盖中日韩，优先简体中文）
      noto-fonts-cjk-serif # Google Noto 宋体/明体
      noto-fonts-color-emoji # 彩色 Emoji 表情字体
      wqy_zenhei # 文泉驿正黑（经典 X11 回退字体）
      wqy_microhei # 文泉驿微米黑
    ];

    fontconfig = {
      defaultFonts = {
        serif = [
          "Noto Serif CJK SC"
          "Noto Serif"
        ];
        sansSerif = [
          "Noto Sans CJK SC"
          "Noto Sans"
        ];
        monospace = [
          "JetBrainsMono Nerd Font"
          "Noto Sans Mono CJK SC"
        ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };

  # ── 2. Fcitx5 输入法 ─────────────────────────
  # [SV8] 配置 Fcitx5 输入法引擎与拼音扩展词库
  # 首次出现的概念：i18n.inputMethod.fcitx5 会自动设置 XMODIFIERS 环境变量与 GTK/Qt 插件
  # 查文档：search.nixos.org 检索 i18n.inputMethod.fcitx5
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      kdePackages.fcitx5-chinese-addons # 拼音、双拼与标点支持
      kdePackages.fcitx5-configtool # 图形化配置面板（支持 Qt6）
      kdePackages.fcitx5-qt # Qt 应用程序输入模块
      fcitx5-gtk # GTK 应用程序输入模块
      fcitx5-pinyin-zhwiki # 维基百科中文词库增强
      fcitx5-rime # Rime 中州韵输入法引擎
    ];
  };
}
