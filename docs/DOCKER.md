# NixOS Docker 容器引擎操作手册 (Docker Manual)

本文档为 NixOS 下 Docker 容器引擎与 Docker Compose 的快速上手与日常运维手册，专为初学者与日常开发设计。

---

## 一、 Docker 核心理念与架构

### 1. 什么是 Docker？
Docker 是一种轻量级的应用容器引擎。与完整虚拟化（如 KVM 虚拟机）不同，Docker **共享宿主机 Linux 内核**，只对进程和文件系统进行命名空间（Namespace）和控制组（Cgroup）的轻量隔离。

在 NixOS 上使用 Docker 的最大优势是：**你可以随时运行任意标准的 Docker 容器（如 Ubuntu、Debian、Alpine 编译链、Node.js、MySQL 等），而无需在 NixOS 本地安装复杂的运行时环境，用完即可随手丢弃，系统保持绝对纯净。**

### 2. 核心三概念通俗比喻

| 概念 | 英文名称 | 形象比喻 | 说明 |
| :--- | :--- | :--- | :--- |
| **镜像** | `Image` | **只读光盘 / 软件模板** | 预先打包好的环境快照（如 Ubuntu 系统或 Nginx 程序），本身是只读的。 |
| **容器** | `Container` | **运行中的独立沙盒** | 从镜像模板实例化跑起来的实际进程。一个镜像可以创建出成百上千个互不干扰的容器。 |
| **数据卷** | `Volume` | **穿透挂载的硬盘** | 容器被销毁后内部数据会消失，数据卷用于将宿主机磁盘目录穿透挂进容器，实现持久化保存。 |

---

## 二、 环境准备与免 Sudo 权限

系统已在 [`modules/virtualisation.nix`](file:///home/flynn/nixos-config/modules/virtualisation.nix) 中固化了 Docker 服务与每周自动清理（`autoPrune`）。

### 1. 检查 Docker 守护进程状态
```bash
docker info
```

### 2. 免提权运行说明
用户已加入系统的 `docker` 用户组。若刚配置完在当前终端执行提示 `permission denied`，只需在当前终端执行一次：
```bash
newgrp docker
```
即可在当前终端立即生效免 `sudo` 执行任何 Docker 命令。

---

## 三、 五分钟极速实战（零基础入门）

### 实战 1：Hello World 验证环境
```bash
docker run hello-world
```
* **发生了什么**：Docker 在本地未找到镜像，自动从官方镜像库（Docker Hub）拉取，并在一个瞬态沙盒里执行并打印一段欢迎文本，执行完毕后自动停止。

---

### 实战 2：一秒开一个一次性 Ubuntu 交互式沙盒
当你需要一个干净的 Linux 环境临时测试命令，又不想弄脏宿主机：
```bash
docker run -it --rm ubuntu bash
```
* 参数解析：
  * `-it`：分配伪终端并开启交互式输入（Interactive Terminal）。
  * `--rm`：**【神级参数】** 容器退出时自动将其从磁盘彻底销毁，不留任何死数据。
  * `ubuntu`：官方 Ubuntu 基础镜像。
  * `bash`：启动后执行的 Shell。
* **尝试在里面操作**：
  ```bash
  cat /etc/os-release   # 此时系统环境已为 Ubuntu
  apt update            # 随意尝试 apt 包管理
  exit                  # 退出并自动销毁，宿主机一尘不染
  ```

---

### 实战 3：一行命令跑本地 Nginx 网页服务器
```bash
docker run -d -p 8080:80 --name my-web nginx
```
* 参数解析：
  * `-d`（Detach）：后台以守护进程模式运行，不霸占当前终端。
  * `-p 8080:80`：端口映射，将本机的 `8080` 端口映射到容器内部的 `80` Web 端口。
  * `--name my-web`：给该容器赋予一个友好的名字 `my-web`。
* **验证效果**：
  打开 Chrome 或 Firefox 浏览器，访问：
  👉 `http://localhost:8080`
  屏幕上即刻呈现 Nginx 的欢迎页面！

---

## 四、 日常高频核心命令速查表 (Cheat Sheet)

### 1. 容器生命周期管理

| 操作 | 命令 | 说明 |
| :--- | :--- | :--- |
| **查看正在运行的容器** | `docker ps` | 查看活跃容器及其分配的端口 |
| **查看所有容器（含已停止）**| `docker ps -a` | 查看全部历史容器 |
| **停止容器** | `docker stop <容器名或ID>` | 优雅发送 SIGTERM 停止服务 |
| **启动已停止的容器** | `docker start <容器名或ID>` | 再次唤醒容器 |
| **重启容器** | `docker restart <容器名或ID>` | 重启容器服务 |
| **删除已停止的容器** | `docker rm <容器名或ID>` | 从磁盘中删除容器实例 |
| **强制杀死并删除容器** | `docker rm -f <容器名或ID>` | 强制中断并即刻删除 |

---

### 2. 镜像管理与磁盘清理

| 操作 | 命令 | 说明 |
| :--- | :--- | :--- |
| **查看本地所有镜像** | `docker images` | 显示本地下载的全部镜像和大小 |
| **删除本地镜像** | `docker rmi <镜像名或ID>` | 从磁盘彻底删除某个镜像 |
| **一键清理虚悬孤儿数据** | `docker system prune` | 清理已停止的容器、未被使用的网络与孤儿镜像 |
| **深度全盘大扫除** | `docker system prune -a --volumes` | 彻底抹除所有未运行的镜像与残留数据卷（谨慎使用） |

---

### 3. 进入容器调试与排障

| 操作 | 命令 | 说明 |
| :--- | :--- | :--- |
| **查看容器实时日志** | `docker logs -f <容器名或ID>` | 类似 `tail -f` 追踪输出日志 |
| **钻进正在运行的容器** | `docker exec -it <容器名或ID> sh` | 在正在运行的容器内部打开一个交互式 Shell |
| **查看容器资源开销** | `docker stats` | 类似 `btop` 实时查看每个容器的 CPU、内存和网络占用 |

---

### 4. 目录穿透挂载（Volume / Bind Mount）
将宿主机真实目录挂载到容器中，容器内生成的文件会实时保存在宿主机上：
```bash
docker run -it --rm -v /home/flynn/my_project:/workspace ubuntu bash
```
> 进入容器后，在 `/workspace` 目录下读写的文件，完全实时等同于在宿主机 `/home/flynn/my_project` 目录下操作。

---

## 五、 Docker Compose 多容器编排

系统已预装 `docker-compose`。在项目根目录下创建一个 `docker-compose.yml` 文件：

```yaml
version: '3.8'

services:
  web:
    image: nginx:alpine
    ports:
      - "8080:80"
    restart: always

  redis:
    image: redis:alpine
    restart: always
```

* **一键启动整套服务集群**：
  ```bash
  docker compose up -d
  ```
* **一键停止并销毁整套集群**：
  ```bash
  docker compose down
  ```

---

## 六、 终端可视化面板推荐：Lazydocker

如果你习惯通过直观的键盘图形界面查看容器状态、实时日志、重启与销毁容器，可以使用极简终端工具 **Lazydocker**，无需事先安装任何包，通过 `nix-shell` 免污染即开即用：

```bash
nix-shell -p lazydocker --run lazydocker
```

* **体验**：终端会瞬间变为双栏控制面板，使用方向键上下移动即可查看容器详情、按 `x` 呼出菜单、按 `l` 查看实时日志，体验极佳。
