# modules/fonts-ime.nix — 字体与 CJK 渲染配置
# 包含：中日韩字体回退、Nerd Fonts 编程图标字体与 Emoji
{ pkgs, ... }:

{
  fonts = {
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono # 英文等宽与编程图标字体
      noto-fonts-cjk-sans # Google Noto 黑体 (中日韩，简体优先)
      noto-fonts-cjk-serif # Google Noto 宋体
      noto-fonts-color-emoji # 彩色 Emoji 表情
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
