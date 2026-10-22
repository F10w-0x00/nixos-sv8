# Panasonic Let's Note CF-SV8 DVD+R 光盘刻录与介质指南

本文档为 Panasonic Let's Note CF-SV8 内置光驱的刻录实战与安全操作手册。

---

## 一、 硬件规格与设备参数 (C1 / R10 实测数据)

经读取内核 sysfs (`/sys/class/block/sr0/device/`) 与 `/proc/sys/dev/cdrom/info` 确认确切硬件信息：

| 属性 | 参数值 | 说明 |
| :--- | :--- | :--- |
| **厂商 (Vendor)** | `HL-DT-ST` | 日立乐金数据存储 (Hitachi-LG Data Storage) |
| **型号 (Model)** | `DVDRAM GUD0N` | 9.5mm 超薄 SATA 内置托盘式 DVD 刻录机 |
| **固件版本 (Rev)** | `PB01` | 原厂稳定版固件 |
| **设备节点** | `/dev/sr0` | 默认只读/读写块设备节点 |
| **设备权限组** | `cdrom` | 已通过 `sv8.nix` §7 自动赋予普通用户免提权访问权限 |
| **介质支持** | CD-R/RW, DVD-R/RW, DVD+R/RW, DVD-RAM | 全格式支持，推荐使用标准 **DVD+R** 介质 |
| **托盘控制** | 软件电磁弹出 (`eject`)，手动轻推收回 | 电磁弹簧释放卡扣，手推复位（笔记本 9.5mm 超薄光驱标准机械设计） |

---

## 二、 核心安全准则（防废盘与防意外）

> [!CAUTION]
> **红线 C0：严禁自动化写入**
> AI 编程助手绝对不会向光盘执行任何物理写入操作。所有包含数据刻录的命令**必须且只能由用户本人在终端手动确认并执行**。

1. **绝对防休眠锁 (`systemd-inhibit`)**：
   笔记本电脑在合盖、静置超时或电源策略触发时可能进入睡眠。**刻录过程中一旦系统挂起，激光头将立刻失电中断，导致盘片永久报废（Buffer Underrun / Coaster）**。
   因此，所有刻录操作必须由 `systemd-inhibit` 前置守护，在刻录结束前强行阻塞休眠与合盖动作。
2. **免提权运行**：
   用户已加入 `cdrom` 用户组，刻录命令**严禁使用 `sudo` 执行**，以避免光驱节点权限被篡改或生成 root 权限镜像。
3. **刻录速度建议**：
   超薄笔记本光驱（9.5mm）机身轻巧、机械防震余量小。推荐将刻录速度固定为 **4x**（约 5.5 MB/s）或 **8x**，切勿使用极限最高速度，以确保刻录坑深稳定和长期数据保存寿命。

---

## 三、 常用只读与检测指令（安全无风险）

### 1. 查询光驱当前状态与托盘介质信息
```bash
dvd+rw-mediainfo /dev/sr0
```
> 若光驱内已插入空白 DVD+R，该命令会输出介质类型（`Media Id`）、剩余容量与支持的写入速度（如 `4.0x`, `8.0x`）。

### 2. 控制光驱托盘弹出与收回
```bash
# 弹出光驱托盘（电磁阀释放卡扣，托盘自动弹出一截，随后用手拉开）
eject /dev/sr0

# 收回光驱托盘：
# 注意：CF-SV8 搭载的 9.5mm 笔记本超薄光驱采用机械手推复位结构（无内部进出仓伺服电机），
# 因此运行 eject -t 会提示不支持，收回时用手轻推托盘至机身咔哒锁紧即可。
```

---

## 四、 DVD+R 刻录实战指令 (Cheat Sheet)

### 场景 A：刻录现有 ISO 镜像至 DVD+R
适用于系统安装盘、WinPE 应急盘或现成光盘镜像：
```bash
systemd-inhibit --what=idle:sleep:handle-lid-switch --who="DVD Burning" --why="Burning ISO to disc" \
  growisofs -dvd-compat -speed=4 -Z /dev/sr0=image.iso
```
* `-dvd-compat`：写入 DVD-ROM 兼容的导入/导出区，提升在老旧 DVD 读取机上的通用读取兼容性。
* `-speed=4`：以稳定 4x 速度平稳刻录。
* `-Z /dev/sr0=image.iso`：以初始写入模式烧录镜像。

---

### 场景 B：直接将本地文件夹打包并刻录（一步到位）
适用于离线数据冷备份、照片与文档归档，无需提前在磁盘生成庞大的临时 ISO 文件：
```bash
systemd-inhibit --what=idle:sleep:handle-lid-switch --who="DVD Burning" --why="Backing up files" \
  growisofs -dvd-compat -speed=4 -Z /dev/sr0 \
    -J -R -V "FLYNN_BACKUP_2026" /path/to/my_data/
```
* `-J`：生成 Joliet 扩展（兼容 Windows 长文件名与 Unicode）。
* `-R`：生成 Rock Ridge 扩展（兼容 Linux 文件权限与大小写敏感）。
* `-V "LABEL"`：指定光盘卷标名（Volume ID，字母大写）。

---

### 场景 C：使用现代化 `xorriso` 工具刻录（高灵活性备选方案）
`xorriso` 提供了高度现代化的镜像处理能力：
```bash
systemd-inhibit --what=idle:sleep:handle-lid-switch --who="DVD Burning" --why="Burning with xorriso" \
  xorriso -as cdrecord -v dev=/dev/sr0 -dao -speed=4 image.iso
```
* `-dao`：Disk-At-Once 整盘一次性刻入模式。

---

## 五、 刻录后完整性校验 (SHA256 Checksum)

刻录完成后，建议立即只读校验数据完整性，确保写入无误：

```bash
# 1. 计算原始 ISO 文件的 SHA256
sha256sum image.iso

# 2. 从光盘读取对应字节数并计算 SHA256（两处哈希值必须完全一致）
head -c $(stat -c %s image.iso) /dev/sr0 | sha256sum
```

---

## 六、 常见问题与排查

1. **提示 `unable to open64("/dev/sr0", O_RDWR): Permission denied`**
   - 原因：当前会话尚未加载新的 `cdrom` 用户组。
   - 解决：运行 `groups` 检查是否包含 `cdrom`；若刚完成 rebuild，请注销桌面会话或重新启动一次。
2. **提示 `FATAL: /dev/sr0 already carries isofs! Use -M to append or -Z to overwrite`**
   - 原因：盘内已有旧文件系统（非全新盘）。
   - 解决：DVD+R 为一次性写入介质，若已封盘（Closed Session）则不可重写；若是 DVD+RW 可重写盘，可加上 `-Z /dev/sr0=...` 强制覆盖，或先运行 `dvd+rw-format -force /dev/sr0` 格式化。
