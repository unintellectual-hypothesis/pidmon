#!/system/bin/sh
# THANKS TO VR-25 @ GitHub
MODDIR=${0%/*}

# Load libraries 
MEM_FEATURES_DIR="$MODULE_PATH/mem-features"
. "$MEM_FEATURES_DIR"/paths.sh

high_load_threshold=""
medium_load_threshold=""
swappiness_change_rate=""
swap_over_hundy=""

# Test if system supports swappiness over 100 (Some ROM defaults swappiness to 100)
test_swappiness()
{
    set_val "180" "$VM"/swappiness
    new_swappiness="$(cat "$VM"/swappiness)"
    if [ "$new_swappiness" -eq 180 ]; then
        swap_over_hundy=1
    else
        swap_over_hundy=0
    fi
}

# Dynamic swappiness & vfs_cache_pressure iff Swap Exists based on /proc/loadavg
start_dynamic_swappiness()
{
    high_load_threshold="$(read_cfg high_load_threshold)"
    [ "$high_load_threshold" == "" ] && high_load_threshold=65
    medium_load_threshold="$(read_cfg medium_load_threshold)"
    [ "$medium_load_threshold" == "" ] && medium_load_threshold=30
    swappiness_change_rate="$(read_cfg swappiness_change_rate)"
    [ "$swappiness_change_rate" == "" ] && swappiness_change_rate=15

    while true; do
    load_avg=$(awk  '{printf "%.0f", ($1 * 100 / 8)}'  /proc/loadavg)
        if [ "$load_avg" -ge "$high_load_threshold" ]; then
            resetprop -n ro.lmk.use_minfree_levels false
            if [ "$swap_over_hundy" -eq 1 ]; then
                set_val "100" "$VM"/swappiness
                set_val "175" "$VM"/vfs_cache_pressure
            elif [ "$swap_over_hundy" -eq 0 ]; then
                set_val "85" "$VM"/swappiness
                set_val "175" "$VM"/vfs_cache_pressure
            fi
        elif [ "$load_avg" -ge "$medium_load_threshold" ]; then
            resetprop -n ro.lmk.use_minfree_levels true
            if [ "$swap_over_hundy" -eq 1 ]; then
                set_val "165" "$VM"/swappiness
                set_val "140" "$VM"/vfs_cache_pressure
            elif [ "$swap_over_hundy" -eq 0 ]; then
                set_val "95" "$VM"/swappiness
                set_val "140" "$VM"/vfs_cache_pressure
            fi
        elif [ "$load_avg" -ge 0 ]; then
            resetprop -n ro.lmk.use_minfree_levels true
            if [ "$swap_over_hundy" -eq 1 ]; then
                set_val "180" "$VM"/swappiness
                set_val "110" "$VM"/vfs_cache_pressure
            elif [ "$swap_over_hundy" -eq 0 ]; then
                set_val "100" "$VM"/swappiness
                set_val "110" "$VM"/vfs_cache_pressure
            fi
        fi
    sleep "$swappiness_change_rate"
  done &
}
