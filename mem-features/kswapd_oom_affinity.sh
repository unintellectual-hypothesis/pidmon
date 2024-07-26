#!/system/bin/sh
# THANKS TO yc9559 @ GitHub
MODDIR=${0%/*}

# Load libraries 
MEM_FEATURES_DIR="$MODULE_PATH/mem-features"
. "$MEM_FEATURES_DIR"/paths.sh

# Change CPU affinity for kswapd and oom_reaper
change_task_affinity()
{
  local ps_right
  ps_right="$(ps -Ao pid,args)"
  for temp_pid in $(echo "$ps_right" | grep "$1" | awk '{print $1}'); do
    for temp_tid in $(ls "/proc/$temp_pid/task/"); do
      taskset -p -- "7f" "$temp_tid"
    done
  done
}

change_task_nice()
{
  local ps_right
  ps_right="$(ps -Ao pid,args)"
  for temp_pid in $(echo "$ps_right" | grep "$1" | awk '{print $1}'); do
    for temp_tid in $(ls "/proc/$temp_pid/task/"); do
      renice -p -n "-2" "$temp_tid"
    done
  done
}