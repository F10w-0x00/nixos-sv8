# NixOS 极简现代化 Python 开发工作流手册 (PYTHON.md)

本文档面向日常开发实战，详细梳理了在 NixOS 上如何通过 **`uv` + `direnv` + `nix flake`** 搭建并高效使用现代化 Python 工作流，覆盖**终端（Terminal）**与 **VSCode** 两大核心工作场景。

---

## 一、 核心架构：三层楼玩具屋（ELI5 极简理解）

在传统 Linux 上，所有第三方库都用 `pip install` 塞进一个全局大抽屉，久而久之依赖冲突打架。  
NixOS 具有纯净性要求，这份工作流将 Python 划分为**三层互不干扰的空间**：

```
┌────────────────────────────────────────────────────────┐
│  三楼：项目层（你自己的小城堡）                          │
│  每个项目目录拥有专属的虚拟环境 (.venv)，依赖锁在 uv.lock │
├────────────────────────────────────────────────────────┤
│  二楼：场景层（四个现成的主题房间，按需直达）             │
│  [算法房 cp]     [数学房 math]    [AI 学习房 ai]   [项目通用 py] │
├────────────────────────────────────────────────────────┤
│  一楼：系统底座（最皮实的通用工具箱）                    │
│  系统只装基础工具：python3、uv、direnv、nix-ld (动态链接器) │
└────────────────────────────────────────────────────────┘
```

- **一楼（系统工具）**：系统全局只保留极简底座，不全局安装任何重型科学计算库。
- **二楼（场景房间）**：通过场景 Flake 预先搭好四个房间。想要算矩阵，推门进数学房；写完代码出门，系统恢复一尘不染。
- **三楼（独立项目）**：正规工程项目使用 `uv` 极速包管理器配合 `direnv` 感应门，进入目录自动激活。

---

## 二、 终端（Terminal）完全使用指南

### 场景 1：临时算数、画图、刷算法题（即开即用，挥挥衣袖不留垃圾）

当你不需要建立项目工程，只是想临时写两行代码、画个图、或者刷 LeetCode 题目：

#### 1. 线性代数与数学计算（NumPy, SciPy, Matplotlib, SymPy, Jupyter）
```bash
# 瞬间进入数学专用环境
nix develop py#math

# 在里面你可以直接交互式运算或画图
python
# 或者进入增强型终端
ipython
```
玩完了，只需输入 `exit` 退出房间，电脑干干净净。

#### 2. 算法竞赛与极速运算（PyPy3, NumPy）
```bash
# 进入算法竞赛环境（包含专为快速提交加速的 pypy3）
nix develop py#cp

pypy3 -c "print(sum(range(10**7)))"
exit
```

#### 3. 深度学习与 AI 实验（PyTorch, Pandas, Scikit-learn）
```bash
# 进入预装了 PyTorch 与数据分析套件的 AI 环境
nix develop py#ai

python -c "import torch; print('PyTorch 版本:', torch.__version__)"
exit
```

---

### 场景 2：正规工程项目（自动感应门 + 极速包管理）

当你打算写一个真正的 Python 工程（如爬虫、API 服务、数据处理管线）：

#### 1. 第一天创建新项目（仅需一次）
```bash
# 1. 创建并进入项目目录
mkdir -p ~/dev/my_project && cd ~/dev/my_project

# 2. 挂上 direnv 自动感应门符咒
echo 'use flake py' > .envrc
direnv allow

# 3. 用 uv 初始化项目（自动生成 pyproject.toml）
uv init
```

#### 2. 日常添加与删除第三方库
> [!IMPORTANT]
> 永远不要在终端直接敲 `pip install`！改用速度快 100 倍的 `uv`：

```bash
# 添加单个或多个库（支持 requests, numpy, fastapi 等任何库）
uv add requests numpy

# 添加开发依赖（比如测试库 pytest）
uv add --dev pytest

# 删除不需要的库
uv remove requests
```

#### 3. 运行你的代码
```bash
# 通过 uv 保证在项目环境下执行
uv run python main.py

# 或者直接执行依赖库提供的 CLI 工具
uv run pytest
```

#### 4. 自动化体验
由于配置了 `direnv`：
- 当你的终端 `cd ~/dev/my_project` 时，终端会自动加载该项目的 Python 与环境变量；
- 当你 `cd ..` 离开目录时，环境自动悄无声息地卸载还原。

---

### 场景 3：单文件脚本免安装直接跑
有时你只是从网上下载了一个单文件 `script.py`，里面用了 `requests`：
```bash
# 不需要创建项目，也不需要提前 pip install，直接跑：
uv run --with requests python script.py
```
`uv` 会在隔离沙箱中下载并执行完毕，用完即焚。

---

## 三、 VSCode 深度集成与高效开发

VSCode 是开发 Python 的图形化利器。通过以下配置，你可以让 VSCode 完美识别环境，拥有完整的代码补全（IntelliSense）、语法跳转与单步断点调试。

### 1. 推荐安装的 VSCode 扩展
在 VSCode 的扩展市场（<kbd>Ctrl + Shift + X</kbd>）中安装以下两个扩展：
1. **`Python`**（ID: `ms-python.python`）：微软官方 Python 语言核心支持；
2. **`direnv`**（ID: `mkhl.direnv`）：让 VSCode 终端与窗口自动同步 direnv 环境变量。

---

### 2. VSCode 连接项目环境步骤

当你按照上一节在终端用 `uv init` 和 `uv add` 创建好项目后，项目根目录下会生成一个 `.venv/` 虚拟环境文件夹。

1. **在项目根目录启动 VSCode**：
   ```bash
   cd ~/dev/my_project
   code .
   ```
2. **指定 Python 解释器（只需首次点一次）**：
   - 按下快捷键 <kbd>Ctrl + Shift + P</kbd> 呼出命令面板；
   - 输入并回车：`Python: Select Interpreter`；
   - 在弹出的列表中选择带有 **`('.venv': poetry/venv)`** 标记的解释器路径：
     ```text
     ./.venv/bin/python
     ```
   - *（VSCode 通常也会在右下角弹出提示：“We noticed a new virtual environment...”，直接点击“Select as Interpreter”即可）*。

---

### 3. 在 VSCode 中开发与调试实战

#### 1. 编写代码与代码补全
- 打开任何 `.py` 文件，所有你用 `uv add` 安装的包（如 `import numpy as np`）都能获得瞬间秒级的补全提示，代码完全没有红色波浪线。

#### 2. 一键运行与断点调试
- **一键运行**：点击编辑器右上角的 **绿色三角箭头（Run Python File）**，脚本即可在内置终端中直接运行出结果。
- **断点调试（Debug）**：
  - 在代码行号左侧单击鼠标左键，打上一个红色的圆点（断点）；
  - 按下 <kbd>F5</kbd> 键（或选择“Python 调试程序: 调试当前文件”）；
  - 程序会精准暂停在断点行，左侧边栏能直观查看所有变量的当前值、调用栈，支持单步步过（<kbd>F10</kbd>）与步入（<kbd>F11</kbd>）。

#### 3. 交互式 Jupyter Notebook 支持
- 如果你在项目中需要数据分析：
  ```bash
  uv add ipykernel matplotlib
  ```
- 在 VSCode 中直接新建或打开 `.ipynb` 文件；
- 点击右上角的 **“选择内核（Select Kernel）”** $\rightarrow$ **“Python 环境”** $\rightarrow$ 选择项目对应的 `.venv/bin/python`；
- 你可以在 Cell 单元格中逐段运行代码、交互式画图与查看数据表格。

---

## 四、 核心排错与最佳实践速查表

| 疑问 / 现象 | 产生原因 | 正确应对方案 |
| :--- | :--- | :--- |
| **直接敲 `pip install` 报错 `externally-managed-environment`** | NixOS 保护系统纯净性，禁止全局直接写文件 | **一律改用 `uv add <包名>`**，把包记录在项目的 `pyproject.toml` 中。 |
| **为什么 `uv` 比传统 `pip` 快那么多？** | `uv` 是用 Rust 重新编写的下一代 Python 包工具，支持全局哈希缓存与并行下载 | 正常现象，其解析依赖和安装 wheel 的速度比 pip 快 10~100 倍。 |
| **下载的预编译二进制包找不到动态库（缺少 `.so`）** | 普通 Linux 发行版依赖 `/lib64/`，NixOS 默认不放置该目录 | 系统已配置 **`nix-ld`** 拦截器，预编译 wheel 会自动链接到正确的系统库，无需手动修补。 |
| **修改了场景配置文件后新环境不生效** | Flake 需要 Git 追踪新状态 | 在对应目录执行 `git add flake.nix flake.lock`，再重新进入环境。 |
