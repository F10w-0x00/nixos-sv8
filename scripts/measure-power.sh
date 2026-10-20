#!/usr/bin/env bash
# ==============================================================================
# scripts/measure-power.sh — 电池放电功率标准化采样脚本
# 用法: ./scripts/measure-power.sh [采样次数(默认60)] [间隔秒数(默认10)]
# 严格按照评审建议 2.2 规程：取 N 次采样的中位数，消除瞬时调度抖动
# ==============================================================================

set -euo pipefail

COUNT="${1:-60}"
INTERVAL="${2:-10}"

# 寻找电池路径 (CF-SV8 通常为 BAT1)
BAT_DIR=""
for b in /sys/class/power_supply/BAT*; do
  if [ -d "$b" ]; then
    BAT_DIR="$b"
    break
  fi
done

if [ -z "$BAT_DIR" ]; then
  echo "错误: 未找到电池设备 (/sys/class/power_supply/BAT*)" >&2
  exit 1
fi

STATUS=$(cat "$BAT_DIR/status" 2>/dev/null || echo "Unknown")
if [ "$STATUS" != "Discharging" ]; then
  echo "警告: 当前电池状态为 [$STATUS]，请拔掉电源后静置 2 分钟再执行测量！" >&2
fi

echo "=========================================================="
echo "开始测量电池放电功率 (设备: ${BAT_DIR##*/}, 状态: $STATUS)"
echo "计划采样: $COUNT 次, 每次间隔: ${INTERVAL}s (预计耗时: $((COUNT * INTERVAL / 60)) 分钟)"
echo "测试前请确保: 屏幕亮度固定、Wi-Fi已连接、无外接设备、电量 30%~90%"
echo "=========================================================="

SAMPLES=()

for i in $(seq 1 "$COUNT"); do
  TIMESTAMP=$(date +"%H:%M:%S")
  
  # 优先读取 power_now (µW)，若无则使用 current_now (µA) * voltage_now (µV) / 10^6
  if [ -f "$BAT_DIR/power_now" ]; then
    P_UW=$(cat "$BAT_DIR/power_now")
  elif [ -f "$BAT_DIR/current_now" ] && [ -f "$BAT_DIR/voltage_now" ]; then
    C_UA=$(cat "$BAT_DIR/current_now")
    V_UV=$(cat "$BAT_DIR/voltage_now")
    P_UW=$(awk "BEGIN { printf \"%.0f\", ($C_UA * $V_UV) / 1000000 }")
  else
    echo "[$TIMESTAMP] 错误: 无法读取放电功率数据" >&2
    exit 1
  fi
  
  P_W=$(awk "BEGIN { printf \"%.3f\", $P_UW / 1000000 }")
  echo "[$TIMESTAMP] 样本 #$i / $COUNT: ${P_W} W"
  SAMPLES+=("$P_UW")
  
  if [ "$i" -lt "$COUNT" ]; then
    sleep "$INTERVAL"
  fi
done

# 计算中位数与极值
printf "%s\n" "${SAMPLES[@]}" | sort -n | awk -v count="$COUNT" '
BEGIN {
  min = 999999999;
  max = 0;
  sum = 0;
}
{
  arr[NR] = $1;
  sum += $1;
  if ($1 < min) min = $1;
  if ($1 > max) max = $1;
}
END {
  median_idx = int(NR / 2) + 1;
  median = arr[median_idx];
  avg = sum / NR;
  
  printf "\n================ 测量结果统计 ================\n";
  printf "有效样本数 : %d\n", NR;
  printf "中位数功率 : \033[1;32m%.2f W\033[0m (Median)\n", median / 1000000;
  printf "平均放电率 : %.2f W (Average)\n", avg / 1000000;
  printf "最低瞬间值 : %.2f W\n", min / 1000000;
  printf "最高瞬间值 : %.2f W\n", max / 1000000;
  printf "==============================================\n";
}
'
