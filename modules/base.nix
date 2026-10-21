# modules/base.nix — 基础系统与包管理器设置
# 包含：Nix 设置、引导加载器、时区与区域语言、用户与基础工具
{ config, pkgs, ... }:

let
  # 引导菜单保留代数上限（防止 /boot 分区被旧内核撑满）
  bootLimit = 3;
in
{
  # ── 1. Nix 包管理器与 Flakes ──────────────────
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true; # 自动硬链接重复文件以节省磁盘空间
  };

  # 定期自动清理超过 7 天的旧包与构建缓存
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # ── 2. 引导加载器 ────────────────────────────
  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = bootLimit;
    };
    efi.canTouchEfiVariables = true; # 允许向主板 NVRAM 注册启动项
  };

  # ── 3. 时区与语言环境 ────────────────────────
  time.timeZone = "Asia/Shanghai";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "zh_CN.UTF-8";
    LC_IDENTIFICATION = "zh_CN.UTF-8";
    LC_MEASUREMENT = "zh_CN.UTF-8";
    LC_MONETARY = "zh_CN.UTF-8";
    LC_NAME = "zh_CN.UTF-8";
    LC_NUMERIC = "zh_CN.UTF-8";
    LC_PAPER = "zh_CN.UTF-8";
    LC_TELEPHONE = "zh_CN.UTF-8";
    LC_TIME = "zh_CN.UTF-8";
  };

  # ── 4. 用户与权限 ────────────────────────────
  users.users.flynn = {
    isNormalUser = true;
    description = "Flynn";
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "audio"
    ];
    packages = with pkgs; [
      vim
      kdePackages.kate
    ];
  };

  # ── 5. 开发工具与运行时环境 ──────────────────
  nixpkgs.config.allowUnfree = true; # 允许安装专有软件（如 VS Code、Intel 固件等）

  # 支持直接运行未针对 Nix 打包的动态链接二进制程序
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc
      zlib
      openssl
      curl
    ];
  };

  environment.localBinInPath = true; # 将 ~/.local/bin 自动加入 PATH

  # 基础版本控制
  programs.git.enable = true;

  # 开发目录环境自动化加载（支持 nix-shell / nix develop 自动生效）
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # 系统常用维护与开发工具
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    pciutils
    usbutils
    tree
    btop
    fastfetch
    gcc
    gdb
    gnumake
    cmake
    cargo
    rustc
    alacritty
    neovim
    vscode
  ];
}
