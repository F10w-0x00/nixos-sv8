# Panasonic CF-SV8 虚拟化与 Windows 虚拟机操作指南

本文档为 Panasonic Let's Note CF-SV8 (Intel Core i7-8665U / 16GB RAM) 在 NixOS 下使用 KVM + Libvirt + Virt-Manager 运行 Windows 10 IoT Enterprise LTSC 2021 虚拟机的完整配置与运维手册。

---

## 一、 虚拟化架构与驱动核心认知

### 1. 技术栈架构

在 NixOS 系统中，我们采用了 Linux 平台性能最佳的原生硬件级虚拟化组合：
* **底层虚拟化引擎**：Linux 内核原生 **KVM**（Kernel-based Virtual Machine），通过 Intel VT-x 硬件指令直接在 CPU 物理核心上运行虚拟机指令。
* **硬件模拟与总线**：精简版 **QEMU-KVM**（仅保留 x86_64 架构，去除无用架构模拟以提升效率）。
* **守护进程与 API**：**Libvirt** 守护进程，搭配 **swtpm** 提供虚拟 TPM 2.0，支持现代安全特性。
* **图形管理器**：**Virt-Manager**，直观的桌面 GUI 控制面板。
* **准虚拟化驱动**：Red Hat **VirtIO** 驱动框架，让虚拟机的磁盘与网络绕过低效的 IDE/SATA 模拟，以接近裸机总线的速度直接通信。

---

### 2. 关键认知：虚拟机中的驱动到底归谁管？

> [!CAUTION]
> **切勿在虚拟机中安装松下官网驱动，也切勿使用“驱动总裁”或“驱动精灵”！**

很多用户在物理机上安装 Windows 11 时习惯去官网下载松下专用驱动（如圆形触控板、电池控制芯片、Hotkey 等）或使用驱动总裁强行补全。**但是在虚拟机沙盒中，两者的驱动逻辑完全不同：**

| 比较维度 | 物理机裸机安装 Windows | 虚拟机沙盒中安装 Windows |
| :--- | :--- | :--- |
| **主板 / 芯片组** | 松下专有主板（需要专有芯片组驱动） | **QEMU 模拟的标准 Q35 主板**（Windows 官方镜像自带驱动，免装） |
| **处理器 (CPU)** | Intel i7-8665U | **host-passthrough 直通**（原生指令集透传，免装驱动） |
| **声卡** | Realtek ALC256 | **QEMU 模拟 Intel HD Audio**（Windows 自带驱动，装完即响） |
| **磁盘控制器** | 物理 SATA / NVMe | **Red Hat VirtIO SCSI 控制器**（由 `virtio-win.iso` 驱动） |
| **网卡 (NIC)** | Intel I219-LM / AC9560 | **Red Hat VirtIO 千兆网卡**（由 `virtio-win.iso` 驱动） |
| **显卡与交互** | Intel UHD 620 核显 | **SPICE QXL / VirtIO 显卡 + Guest Agent**（由 `virtio-win.iso` 驱动） |

* **为什么不能装松下官网驱动**：虚拟机 BIOS 呈现的硬件 ID 是 `QEMU`，松下安装包检测到非松下物理主板会直接报错弹窗并拒绝运行。
* **为什么不能用驱动总裁**：第三方驱动工具对虚拟机虚拟总线支持极差，极易误推错误驱动造成 Windows 蓝屏，且会捆绑广告全家桶。
* **黄金准则**：在虚拟机中，**Windows 原生自带驱动 + Red Hat VirtIO 驱动包**就是全部，设备管理器全绿 0 感叹号，极其纯净。

---

## 二、 虚拟化环境就绪验证

系统已在 [`modules/virtualisation.nix`](file:///home/flynn/nixos-config/modules/virtualisation.nix) 中固化了完整支持：

1. **确认 VirtIO 驱动光盘软链接**：
   ```bash
   ls -la /run/current-system/sw/share/virtio-win/virtio-win.iso
   ```
2. **确认主用户已加入 `libvirtd` 组**：
   ```bash
   groups | grep libvirtd
   ```
   > 若当前终端刚配置完尚未生效，可执行一次 `newgrp libvirtd` 立即获得免 root 提权权限。

---

## 三、 Windows 10 LTSC 虚拟机创建全流程

### 步骤 1：新建虚拟机向导
1. 打开终端输入 `virt-manager`（或按 `Mod + p` 键入 `virt-manager` 启动）。
2. 点击左上角 **新建虚拟机** 图标（显示器带加号）：
   - **第 1 步**：选择 **本地安装介质 (ISO 镜像或光驱)** -> 点击“前进”。
   - **第 2 步**：浏览选择下载好的 `en-us_windows_10_iot_enterprise_ltsc_2021_x64_dvd_257ad90f.iso` 镜像；下方系统类型选择 **Microsoft Windows 10**。
   - **第 3 步**：内存分配推荐 **4096 MB ~ 6144 MB**（4G~6G 足够流畅运行），CPU 核心数填 **4**。
   - **第 4 步**：启用存储卷，建议分配 **40 GB ~ 60 GB**（动态 qcow2 格式，用多少实际占多少磁盘空间）。
   - **第 5 步**：**【关键】勾选「在安装前自定义配置」（Customize configuration before install）**，再点击“完成”。

---

### 步骤 2：核心性能调优与硬件配置（榨干 i7-8665U 性能）
在弹出的自定义配置窗口中，按以下顺序调整：

1. **CPU 模式直通**：
   - 点击左侧 **CPU** 项。
   - **配置模型 (Model)**：填入或选择 **`host-passthrough`**。
   - 展开拓扑：勾选手动设置，Sockets: 1, Cores: 4, Threads: 1。
   - *效果：使虚拟机完全继承物理 i7-8665U 的所有硬件特性与指令集（AVX2、AES-NI 等），性能损耗低于 3%。*
2. **固件引导 (Firmware)**：
   - 点击左侧 **Overview（概览）**。
   - 芯片组选择 **`Q35`**。
   - 固件选择 **`UEFI x86_64: ...OVMF_CODE.fd`**（现代 Windows 强烈推荐 UEFI 引导）。
3. **磁盘总线切换为 VirtIO**：
   - 点击左侧 **SATA Disk 1**。
   - 将 **磁盘总线 (Disk bus)** 改为 **`VirtIO`**。
   - 缓存模式选择 **`writeback`** 或 **`none`**。
4. **虚拟网卡切换为 VirtIO**：
   - 点击左侧 **NIC（网卡）**。
   - 将 **设备型号 (Device model)** 改为 **`virtio`**。
5. **挂载 VirtIO 驱动光盘**：
   - 点击窗口左下角 **“添加硬件” -> “存储”**。
   - 设备类型选择 **`CDROM 设备`**。
   - 路径浏览选择系统提供的镜像文件：
     `/run/current-system/sw/share/virtio-win/virtio-win.iso`
6. **显示与显卡协议**：
   - **Display Spice**：保持默认 Spice 协议。
   - **Video**：选择 **`QXL`** 或 **`Virtio`**。

确认全部修改后，点击左上角 **“开始安装”**。

---

### 步骤 3：Windows 安装过程加载 VirtIO 存储驱动
1. 虚拟机开机，出现 `Press any key to boot from CD or DVD...` 时迅速按回车进入安装界面。
2. 语言键盘确认后，点击“现在安装”。
3. 许可协议勾选同意，安装类型务必选择 **「自定义：仅安装 Windows（高级）」**。
4. **解决找不到驱动器**：
   - 界面提示 *“找不到任何驱动器”*（因为磁盘是 VirtIO 接口，微软镜像原生未内置该驱动）。
   - 点击列表下方的 **「加载驱动程序」（Load driver）** -> 点击 **「浏览」**。
   - 在弹出的盘符列表中，展开第二个驱动器（`virtio-win` 光盘）。
   - 展开路径：`vioscsi` -> `w10` -> `amd64`（或 `viostor` -> `w10` -> `amd64`），点击“确定”。
   - 选中识别出的 **`Red Hat VirtIO SCSI controller`**，点击“下一步”。
5. 此时刚才分配的虚拟硬盘立即出现，点击“下一步”正常进行系统复制与安装。

---

### 步骤 4：安装完成后的 Guest Tools 增强（剪贴板互通与自适应）
进入 Windows 10 LTSC 桌面后，只需完成最后一步整合：

1. 打开“此电脑”（文件资源管理器），双击进入挂载的 `virtio-win` 驱动光盘。
2. 双击运行根目录下的 **`virtio-win-gt-x64.exe`**。
3. 按照向导全部点击“下一步”完成安装。

**安装完成效果**：
- **双向剪贴板无缝互通**：Linux 与 Windows 之间可以直接复制粘贴文本与图片。
- **分辨率随窗口自适应**：随意缩放 Virt-Manager 窗口，虚拟机桌面自动无黑边拉伸匹配。
- **鼠标无缝进出**：鼠标移入移出虚拟机无需按释放键，毫无延迟。

---

## 四、 虚拟机常用运维管理速查

### 1. USB 物理设备直通（如插上真实 U 盘）
Virt-Manager 运行中，点击菜单栏 **虚拟机 -> 重定向 USB 设备**，在勾选框中勾选你要连入虚拟机的 U 盘或加密狗，该设备就会瞬间从 Linux 卸载并接入到 Windows 中。

### 2. 快照管理（防折腾神器）
在对虚拟机进行重大软件测试前，点击 Virt-Manager 工具栏的 **快照管理图标**（带摄像头的按钮），点击左下角 **+ 号** 创建快照。测试失败随时可一秒回滚到初始干净状态。

### 3. 命令行 virsh 快速操控
无需打开 GUI 也可通过终端快速控制：
```bash
virsh list --all               # 查看所有虚拟机状态
virsh start win10              # 启动名为 win10 的虚拟机
virsh shutdown win10           # 优雅关机
virsh destroy win10            # 强制断电
virsh snapshot-list win10      # 查看快照列表
```
