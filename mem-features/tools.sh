#!/system/bin/sh
# THANKS TO yc9559 @ GitHub

# Load libraries 
MEM_FEATURES_DIR="$MODULE_PATH/mem-features"
. "$MEM_FEATURES_DIR"/paths.sh

# To change parameter values
set_val()
{
    if [ -f "$2" ]; then
        chmod 0666 "$2" 2> /dev/null
        echo "$1" > "$2"
    fi
}

# Config file stuffs
clear_cfg()
{
    true > "$CFG_FILE"
}

write_cfg()
{
    echo "$1" >> "$CFG_FILE"
}

read_cfg()
{
    local read_metadata
    if [ -f "$CFG_FILE" ]; then
        read_metadata="$(grep "^$1=" "$CFG_FILE" | head -n 1 | tr -d ' ' | cut -d= -f2)"
    fi
    echo "$read_metadata"
}

wait_until_unlock()
{
  while [ ! -d "/sdcard/Android" ]; do
    sleep 1
  done
}

# Swapoff all device
swap_all_off()
{
    for zr in $(cat /proc/swaps | grep "^/" | awk '{print $1}'); do
        $TB swapoff "$zr"
    done
    
    # Resets ZRAM
    set_val "1" $ZRAM_SYS/reset
}

get_avail_comp_algo()
{
    # Linux 3.x may not have comp_algorithm tunable
    if [ -f "$ZRAM_SYS/comp_algorithm" ]; then
        # "lz4 [lzo] deflate", remove '[' and ']'
        echo "$(cat "$ZRAM_SYS"/comp_algorithm | sed "s/\[//g" | sed "s/\]//g")"
    else
        # lzo is the default comp_algorithm since Linux 2.6
        echo "lzo"
    fi
}

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

# Return:status
fscc_status() {
	# Get the correct value after waiting for fscc loading files
	sleep 2
	[[ "$(pgrep -f "fscache-ctrl")" ]] && echo "Running $(cat /proc/meminfo | grep Mlocked | cut -d: -f2 | tr -d ' ') in cache." || echo "Not running."
}