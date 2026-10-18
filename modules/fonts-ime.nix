# modules/fonts-ime.nix — 字体与 CJK 阅读支持
# 作用：中日韩字体配置、Fontconfig 回退优先级（仅阅读，不启用输入法）
# 依赖：无
# 目录：1. 字体包与 Fontconfig 默认值
{ pkgs, ... }:

{
  # ── 1. 字体包与 Fontconfig 默认值 ────────────
  # 保留完整 CJK 中日英字体支持，满足网页、文档与终端阅读需求；不启用输入法
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
}
