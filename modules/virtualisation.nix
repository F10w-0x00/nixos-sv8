# modules/virtualisation.nix — 虚拟化与虚拟机支持 (KVM + Libvirt + Virt-Manager)
# 提供硬件级虚拟化加速、UEFI (OVMF) 固件、虚拟 TPM 2.0 (swtpm)、USB 重定向与 VirtIO 驱动
{ pkgs, ... }:

{
  # ── 1. Libvirt 与 QEMU / KVM 守护进程 ──────────────
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm; # 使用轻量级 KVM 专用构建（仅保留 x86/KVM，节省磁盘与带宽）
      swtpm.enable = true;    # 启用虚拟 TPM 2.0 (swtpm)，支持 Windows 10/11 安全特性
    };
  };

  # ── 2. Virt-Manager 图形管理器与 DConf ──────────────
  programs.virt-manager.enable = true;
  programs.dconf.enable = true;

  # ── 3. SPICE USB 重定向支持 ─────────────────────────
  virtualisation.spiceUSBRedirection.enable = true;

  # ── 4. 用户组权限 ──────────────────────────────────
  # 赋予主用户管理虚拟机权限（无需每次提权输入 root 密码）
  users.users.flynn.extraGroups = [ "libvirtd" ];

  # ── 5. 虚拟化配套客户端与驱动工具 ──────────────────
  environment.systemPackages = with pkgs; [
    virt-viewer            # SPICE / VNC 客户端
    spice                  # SPICE 协议核心
    spice-gtk              # GTK SPICE 客户端支持库
    virtio-win             # Windows VirtIO 驱动解压目录
    # 提供直接可挂载的 virtio-win.iso 软链接，位于 /run/current-system/sw/share/virtio-win/virtio-win.iso
    (runCommand "virtio-win-iso" { } ''
      mkdir -p $out/share/virtio-win
      ln -s ${pkgs.virtio-win.src} $out/share/virtio-win/virtio-win.iso
    '')
  ];
}
