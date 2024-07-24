#!/system/bin/sh
# THANKS TO VR-25 @ GitHub

# load libraries
CURR_DIR="$(dirname "$0")"
. $CURR_DIR/TOOLS.sh

high_load_threshold=""
medium_load_threshold=""
swap_over_hundy=0

# Test if kernel supports swappiness over 100 (Some ROM defaults swappiness to 100)
test_swappiness()
{
  set_value "200" $VM/swappiness
  new_swappiness=$(cat $VM/swappiness)
  if [ "$new_swappiness" -eq 200 ]; then
    swap_over_hundy=1
  else
    swap_over_hundy=0
  fi
}

# Dynamic swappiness & vfs_cache_pressure iff Swap Exists based on /proc/loadavg
start_dynamic_swappiness()
{
  while [ "$(awk '/^SwapTotal:/{print $2}' /proc/meminfo)" != 0 ]; do
  load_avg=$(awk  '{printf "%.0f", ($1 * 100 / 8)}'  /proc/loadavg)
    if [ "$load_avg" -ge "$(read_cfg high_load_threshold)" ]; then
      resetprop -n ro.lmk.use_minfree_levels false
      if [ "$swap_over_hundy" -eq 1 ]; then
        set_value "100" $VM/swappiness
        set_value "175" $VM/vfs_cache_pressure
      elif [ "$swap_over_hundy" -eq 0 ]; then
        set_value "85" $VM/swappiness
        set_value "175" $VM/vfs_cache_pressure
      fi
    elif [ "$load_avg" -ge "$(read_cfg medium_load_threshold)" ]; then
      resetprop -n ro.lmk.use_minfree_levels true
      if [ "$swap_over_hundy" -eq 1 ]; then
        set_value "165" $VM/swappiness
        set_value "140" $VM/vfs_cache_pressure
      elif [ "$swap_over_hundy" -eq 0 ]; then
        set_value "90" $VM/swappiness
        set_value "140" $VM/vfs_cache_pressure
      fi
    elif [ "$load_avg" -ge 0 ]; then
      resetprop -n ro.lmk.use_minfree_levels true
      if [ "$swap_over_hundy" -eq 1 ]; then
        set_value "180" $VM/swappiness
        set_value "110" $VM/vfs_cache_pressure
      elif [ "$swap_over_hundy" -eq 0 ]; then
        set_value "100" $VM/swappiness
        set_value "110" $VM/vfs_cache_pressure
      fi
    fi
    sleep 15
  done &
}