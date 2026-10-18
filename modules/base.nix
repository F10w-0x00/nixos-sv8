# modules/base.nix — 基础系统与 Nix 配置
# 作用：Nix 设置、引导加载器、时区与区域语言、用户与权限、基础 CLI 工具
# 依赖：无
# 目录：1. Nix 与 Flakes 设置  2. 引导加载器  3. 时区与 Locale  4. 用户与权限  5. 基础系统工具与动态链接
{ config, pkgs, ... }:

let
  # 引导菜单保留代数上限。可改：整数值（如 5 到 20）
  bootLimit = 10;
in
{
  # ── 1. Nix 与 Flakes 设置 ────────────────────
  # 首次出现的概念：experimental-features 开启 Nix 新版命令行和 Flake 声明式管理
  # 查文档：man nix.conf / search.nixos.org 检索 nix.settings
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true; # 自动硬链接重复文件以节省 SSD 空间
    # [ALT] 暂不开启 nix.gc 自动清理，避免构建缓存被冲掉；日常由用户按需执行 nix-collect-garbage
  };

  # ── 2. 引导加载器 ────────────────────────────
  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = bootLimit; # [SV8] 防止 1GB /boot 分区被多代旧内核撑爆
    };
    efi.canTouchEfiVariables = true; # 允许向主板 NVRAM 注册 UEFI 启动项
  };

  # ── 3. 时区与 Locale ─────────────────────────
  time.timeZone = "Asia/Shanghai"; # [SV8] 经 timedatectl 核实为当前时区
  i18n.defaultLocale = "en_US.UTF-8"; # 系统消息与终端默认保持英文以防乱码
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
    ]; # 授予网络配置与提权权限
    packages = with pkgs; [
      vim
      kdePackages.kate
    ];
  };

  # ── 5. 基础系统工具与动态链接 ────────────────
  nixpkgs.config.allowUnfree = true; # 允许安装专有软件（如 VS Code、微码等）

  # 允许运行非 Nix 预编译的动态链接二进制（如 VS Code Server 等）
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc
      zlib
      openssl
      curl
    ];
  };

  environment.localBinInPath = true; # 将 ~/.local/bin 自动加入 PATH 环境变量

  # 系统级基础排障与维护工具
  environment.systemPackages = with pkgs; [
    vim
    git
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
    alacritty
    neovim
    vscode
  ];
}
