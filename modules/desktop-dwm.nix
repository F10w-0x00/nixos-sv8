# modules/desktop-dwm.nix — X11 与 DWM 极简平铺桌面环境
# 包含：DWM 窗口管理器源码定制、Suckless 核心工具链、状态栏、锁屏与终端
{
  config,
  lib,
  pkgs,
  ...
}:

let
  # 屏幕 DPI（优先读取主机层设定，未设定时安全回落至标准 96 DPI）
  targetDpi = if config.services.xserver.dpi != null then config.services.xserver.dpi else 96;

  # 桌面壁纸（自包含于仓库 wallpapers/ 目录下，随构建打包进系统）
  wallpaperPath = ../wallpapers/wallpaper.png;

  # 音量与输出路由状态检测（支持毫秒级检测 PipeWire 外放/耳机与静音状态）
  getVolumeScript = pkgs.writeShellScriptBin "get-volume-status" ''
    vol_line=$(${pkgs.wireplumber}/bin/wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || true)
    if [ -z "$vol_line" ]; then
      echo "n/a"
      exit 0
    fi

    raw_vol=$(echo "$vol_line" | ${pkgs.gawk}/bin/awk '{print $2}')
    is_muted=0
    if echo "$vol_line" | ${pkgs.gnugrep}/bin/grep -q "MUTED"; then
      is_muted=1
    fi

    vol_pct=$(${pkgs.gawk}/bin/awk -v v="$raw_vol" 'BEGIN { printf "%d", int(v * 100 + 0.5) }')

    route_out=$(${pkgs.wireplumber}/bin/wpctl get-route @DEFAULT_AUDIO_SINK@ 2>/dev/null || true)
    is_headphone=0
    if echo "$route_out" | ${pkgs.gnugrep}/bin/grep -qE '^\s*\*\s+[0-9]+.*(Headphone|Headset)'; then
      is_headphone=1
    fi

    if [ "$is_headphone" -eq 1 ]; then
      if [ "$is_muted" -eq 1 ]; then
        echo "󰋋 MUT"
      else
        echo "󰋋 $vol_pct%"
      fi
    else
      if [ "$is_muted" -eq 1 ]; then
        echo "󰖁 MUT"
      else
        echo "󰕾 $vol_pct%"
      fi
    fi
  '';

  # 截图与标注交互流脚本（maim 区域截取 + Satty 极速标注 + xclip 剪贴板 + 自动归档）
  screenshotScript = pkgs.writeShellScriptBin "dwm-screenshot" ''
    set -euo pipefail

    TARGET_DIR="$HOME/Pictures/Screenshots"
    mkdir -p "$TARGET_DIR"

    TMP_SHOT=$(mktemp /tmp/satty-XXXXXX.png)
    trap 'rm -f "$TMP_SHOT"' EXIT

    if [ "''${1:-}" = "--full" ]; then
      MAIM_ARGS=(-u)
    else
      MAIM_ARGS=(-u -s)
    fi

    if ${pkgs.maim}/bin/maim "''${MAIM_ARGS[@]}" "$TMP_SHOT" 2>/dev/null && [ -s "$TMP_SHOT" ]; then
      ${pkgs.satty}/bin/satty \
        --filename "$TMP_SHOT" \
        --output-filename "$TARGET_DIR/Screenshot_%Y-%m-%d_%H-%M-%S.png" \
        --copy-command "${pkgs.xclip}/bin/xclip -selection clipboard -t image/png" \
        --early-exit all \
        --save-after-copy
    fi
  '';

  # Speedrun 极简竞速跑表与倒计时提醒脚本
  speedrunTimerScript = pkgs.writeShellScriptBin "speedrun-timer" ''
    set -euo pipefail

    STATE_DIR="''${XDG_RUNTIME_DIR:-/tmp}/speedrun-timer"
    STATE_FILE="''$STATE_DIR/state"

    mkdir -p "''$STATE_DIR"

    format_time() {
      local total="''$1"
      local h=$((total / 3600))
      local m=$(((total % 3600) / 60))
      local s=$((total % 60))
      printf "%02d:%02d:%02d" "''$h" "''$m" "''$s"
    }

    parse_duration() {
      local input="''$1"
      local total=0
      if [[ "''$input" =~ ^[0-9]+$ ]]; then
        total=$((input * 60))
      else
        local num=""
        for (( i=0; i<''${#input}; i++ )); do
          char="''${input:$i:1}"
          case "''$char" in
            [0-9]) num="''${num}''${char}" ;;
            h|H) total=$((total + num * 3600)); num="" ;;
            m|M) total=$((total + num * 60)); num="" ;;
            s|S) total=$((total + num)); num="" ;;
          esac
        done
        if [ -n "''$num" ]; then
          total=$((total + num * 60))
        fi
      fi
      echo "''$total"
    }

    cmd="''${1:-}"

    case "''$cmd" in
      status)
        if [ ! -f "''$STATE_FILE" ]; then
          printf "[00:00:00] "
          exit 0
        fi

        mode="" status="" start_ts=0 paused_accum=0 target_secs=0 notified=0
        . "''$STATE_FILE" 2>/dev/null || { printf "[00:00:00] "; exit 0; }

        now=''${EPOCHSECONDS}

        if [ "''$status" = "running" ]; then
          if [ "''$mode" = "stopwatch" ]; then
            elapsed=$((now - start_ts + paused_accum))
            printf "[󰐕 %s] " "$(format_time "''$elapsed")"
          elif [ "''$mode" = "countdown" ]; then
            elapsed=$((now - start_ts))
            remaining=$((target_secs - elapsed))
            if [ "''$remaining" -gt 0 ]; then
              printf "[󰍴 %s] " "$(format_time "''$remaining")"
            else
              if [ "''$notified" -eq 0 ]; then
                sed -i 's/^notified=0/notified=1/' "''$STATE_FILE" 2>/dev/null || true
                ${pkgs.libnotify}/bin/notify-send -u critical -a "Timer" "⏰ 时间到！" "您设定的倒计时已完成！" 2>/dev/null || true
              fi
              printf "[󰄬 00:00:00] "
            fi
          else
            printf "[00:00:00] "
          fi
        elif [ "''$status" = "paused" ]; then
          if [ "''$mode" = "stopwatch" ]; then
            printf "[󰏤 %s] " "$(format_time "''$paused_accum")"
          elif [ "''$mode" = "countdown" ]; then
            printf "[󰏤 %s] " "$(format_time "''$target_secs")"
          else
            printf "[󰏤 00:00:00] "
          fi
        else
          printf "[00:00:00] "
        fi
        ;;

      run|start)
        now=''${EPOCHSECONDS}
        cat <<EOF > "''$STATE_FILE"
mode=stopwatch
status=running
start_ts=''${now}
paused_accum=0
target_secs=0
notified=0
EOF
        echo "Speedrun stopwatch started."
        ;;

      pause)
        if [ -f "''$STATE_FILE" ]; then
          mode="" status="" start_ts=0 paused_accum=0 target_secs=0 notified=0
          . "''$STATE_FILE" 2>/dev/null || exit 0
          if [ "''$status" = "running" ]; then
            now=''${EPOCHSECONDS}
            if [ "''$mode" = "stopwatch" ]; then
              paused_accum=$((now - start_ts + paused_accum))
            elif [ "''$mode" = "countdown" ]; then
              target_secs=$((target_secs - (now - start_ts)))
              if [ "''$target_secs" -lt 0 ]; then target_secs=0; fi
            fi
            cat <<EOF > "''$STATE_FILE"
mode=''${mode}
status=paused
start_ts=''${now}
paused_accum=''${paused_accum}
target_secs=''${target_secs}
notified=''${notified}
EOF
            echo "Timer paused."
          fi
        fi
        ;;

      resume)
        if [ -f "''$STATE_FILE" ]; then
          mode="" status="" start_ts=0 paused_accum=0 target_secs=0 notified=0
          . "''$STATE_FILE" 2>/dev/null || exit 0
          if [ "''$status" = "paused" ]; then
            now=''${EPOCHSECONDS}
            cat <<EOF > "''$STATE_FILE"
mode=''${mode}
status=running
start_ts=''${now}
paused_accum=''${paused_accum}
target_secs=''${target_secs}
notified=''${notified}
EOF
            echo "Timer resumed."
          fi
        fi
        ;;

      toggle)
        if [ ! -f "''$STATE_FILE" ]; then
          exec "''$0" run
        fi
        mode="" status="" start_ts=0 paused_accum=0 target_secs=0 notified=0
        . "''$STATE_FILE" 2>/dev/null || { exec "''$0" run; }
        if [ "''$status" = "running" ]; then
          exec "''$0" pause
        elif [ "''$status" = "paused" ]; then
          exec "''$0" resume
        else
          exec "''$0" run
        fi
        ;;

      stop|reset)
        rm -f "''$STATE_FILE"
        echo "Timer reset to 00:00:00."
        ;;

      *)
        if [ -n "''$cmd" ]; then
          secs=$(parse_duration "''$cmd")
          if [ "''$secs" -gt 0 ]; then
            now=''${EPOCHSECONDS}
            cat <<EOF > "''$STATE_FILE"
mode=countdown
status=running
start_ts=''${now}
paused_accum=0
target_secs=''${secs}
notified=0
EOF
            echo "Countdown timer started for $(format_time "''$secs")."
          else
            echo "Usage: timer [run|start|pause|resume|toggle|stop|reset|<duration>]"
            echo "Examples: timer run, timer 25m, timer 15, timer stop"
          fi
        else
          if [ -f "''$STATE_FILE" ]; then
            . "''$STATE_FILE" 2>/dev/null || true
            echo "Timer mode: ''$mode, status: ''$status"
          else
            echo "Timer idle (00:00:00)."
          fi
        fi
        ;;
    esac
  '';

  # Speedrun 计时器 dmenu 快速交互菜单
  speedrunTimerMenu = pkgs.writeShellScriptBin "speedrun-timer-menu" ''
    CHOICE=$(printf "▶ 开启正向竞速跑表 (Speedrun)\n⏱ 倒计时 25 分钟 (番茄钟)\n⏱ 倒计时 15 分钟\n⏱ 倒计时 45 分钟\n⏱ 倒计时 60 分钟\n⏸ 暂停 / 继续计时\n⏹ 停止并重置 (00:00:00)" | ${customDmenu}/bin/dmenu -i -p "Timer: ")

    case "''$CHOICE" in
      *"正向竞速"*) ${speedrunTimerScript}/bin/speedrun-timer run ;;
      *"25 分钟"*)  ${speedrunTimerScript}/bin/speedrun-timer 25m ;;
      *"15 分钟"*)  ${speedrunTimerScript}/bin/speedrun-timer 15m ;;
      *"45 分钟"*)  ${speedrunTimerScript}/bin/speedrun-timer 45m ;;
      *"60 分钟"*)  ${speedrunTimerScript}/bin/speedrun-timer 60m ;;
      *"暂停"*)      ${speedrunTimerScript}/bin/speedrun-timer toggle ;;
      *"停止"*)      ${speedrunTimerScript}/bin/speedrun-timer stop ;;
      *)
        if [ -n "''$CHOICE" ]; then
          ${speedrunTimerScript}/bin/speedrun-timer "''$CHOICE"
        fi
        ;;
    esac
  '';

  # 命令行简短别名 timer -> speedrun-timer
  timerAlias = pkgs.writeShellScriptBin "timer" ''
    exec ${speedrunTimerScript}/bin/speedrun-timer "$@"
  '';

  # Suckless 工具链定制编译注入
  customDwm = pkgs.dwm.override {
    conf = ../pkgs/dwm/config.h;
  };
  customDmenu = pkgs.dmenu.override {
    conf = ../pkgs/dmenu/config.h;
  };
  customSlstatus = pkgs.slstatus.override {
    conf = pkgs.replaceVars ../pkgs/slstatus/config.h.in {
      batteryName = config.my.batteryName;
      getVolumeCmd = "${getVolumeScript}/bin/get-volume-status";
      getTimerCmd = "${speedrunTimerScript}/bin/speedrun-timer status";
    };
  };
in
{
  # ── 自定义通用配置选项 ───────────────────────
  options.my = {
    batteryName = lib.mkOption {
      type = lib.types.str;
      default = "BAT0";
      description = "电池设备名称，用于 slstatus 状态栏显示";
    };
  };

  config = {
    # ── 1. 显示与 DPI 设置 ────────────────────────
    services.xserver = {
      enable = true;
      dpi = lib.mkDefault 96;
    };

    # ── 2. TTY 自动登录与 startx ────────────────
    # tty1 免密码自动登录
    services.getty.autologinUser = "flynn";

    # 登录 tty1 时自动启动 X11 会话，其余 tty 保持纯终端用于排障
    environment.loginShellInit = ''
      if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
        exec startx
      fi
    '';

    # 会话环境初始化脚本
    services.xserver.displayManager.startx = {
      enable = true;
      generateScript = true;
      extraCommands = ''
        # 导出环境变量给 systemd 用户服务与 D-Bus
        export XDG_CURRENT_DESKTOP=dwm
        systemctl --user import-environment DISPLAY XAUTHORITY XDG_CURRENT_DESKTOP
        ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd DISPLAY XAUTHORITY XDG_CURRENT_DESKTOP

        # 设定全局渲染 DPI
        echo "Xft.dpi: ${toString targetDpi}" | ${pkgs.xrdb}/bin/xrdb -merge -

        # 默认光标形状
        ${pkgs.xsetroot}/bin/xsetroot -cursor_name left_ptr &

        # 加载自包含壁纸
        ${pkgs.feh}/bin/feh --bg-fill ${wallpaperPath} &

        # 桌面通知守护进程
        ${pkgs.dunst}/bin/dunst &

        # 空闲与休眠自动锁屏联动 (slock)
        ${pkgs.xss-lock}/bin/xss-lock --transfer-sleep-lock -- ${pkgs.slock}/bin/slock &

        # 可移动存储设备自动挂载
        ${pkgs.udiskie}/bin/udiskie --no-notify &

        # 启动顶部状态栏
        ${customSlstatus}/bin/slstatus &
      '';
    };

    # ── 3. DWM 窗口管理器 ────────────────────────
    services.xserver.windowManager.dwm = {
      enable = true;
      package = customDwm;
    };

    # ── 4. 桌面配套工具 ──────────────────────────
    # 仅负责 VSync 垂直同步的极简 picom 合成器：
    # 彻底杜绝网页与 PDF 快速滑动时的画面撕裂（Screen Tearing）
    # 彻底关闭所有阴影、渐变淡入淡出、窗口透明与毛玻璃等重度特效，保持零视觉延迟与最低功耗
    services.picom = {
      enable = true;
      backend = "glx"; # 采用 OpenGL 硬件渲染后端（Intel UHD 620 核显成熟稳定）
      vSync = true; # 强制锁死 60Hz 垂直同步，根除滚动撕裂
      shadow = false; # 彻底禁用窗口阴影
      fade = false; # 彻底禁用窗口淡入淡出动画
      activeOpacity = 1.0;
      inactiveOpacity = 1.0;
      settings = {
        # 增量渲染优化：仅在屏幕区域发生像素变化时重绘对应区域，杜绝全屏无谓刷新
        use-damage = true;
        # 全屏应用/视频播放时自动解除重定向（直通渲染），杜绝输入延迟
        unredir-if-possible = true;
      };
    };

    programs.slock.enable = true; # 开启 setuid 权限支持校验用户密码

    environment.systemPackages = with pkgs; [
      getVolumeScript # 音量与输出设备状态检测脚本
      screenshotScript # 截图标注交互包装脚本 (dwm-screenshot)
      speedrunTimerScript # Speedrun 竞速跑表与倒计时主脚本 (speedrun-timer)
      speedrunTimerMenu # Speedrun 计时器 dmenu 快速交互菜单 (speedrun-timer-menu)
      timerAlias # 计时器便捷简短别名 (timer)
      customDmenu # dmenu 应用启动器
      customSlstatus # slstatus 状态栏
      brightnessctl # 屏幕背光调节工具
      maim # 屏幕截图工具
      satty # 现代轻量截图标注工具
      xclip # 剪贴板管理工具
      feh # 壁纸加载与看图工具
      dunst # 桌面通知服务
      libnotify # notify-send 工具
      xss-lock # 自动锁屏联动
      udiskie # 存储设备自动挂载
      xsetroot # X 根窗口管理
      xrdb # X 资源数据库配置
      xev # 按键测试工具
    ];
  };
}
