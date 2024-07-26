#!/system/bin/sh
# Constructed by: free @ Telegram // unintellectual-hypothesis @GitHub
MODDIR=${0%/*}

# Set Original Module Directory
MODULE_PATH="$(dirname $(readlink -f "$0"))"
MODULE_PATH="${MODULE_PATH%/variants}"

# load libraries
MEM_FEATURES_DIR="$MODULE_PATH/mem-features"
. "$MEM_FEATURES_DIR"/tools.sh
. "$MEM_FEATURES_DIR"/intelligent_zram_writeback.sh

zram_disksize=""
zram_algo=""

# Test if kernel supports swappiness over 100 (Some ROM defaults swappiness to 100)
test_swappiness()
{
  set_val "180" "$VM"/swappiness
  new_swappiness=$(cat "$VM"/swappiness)
  if [ "$new_swappiness" -eq 180 ]; then
    swap_over_hundy=1
  else
    swap_over_hundy=0
  fi
}

conf_vm_param()
{
    set_val "10" "$VM"/dirty_ratio
    set_val "3" "$VM"/dirty_background_ratio
    set_val "76800" "$VM"/extra_free_kbytes
    set_val "8192" "$VM"/min_free_kbytes
    set_val "3000" "$VM"/dirty_expire_centisecs
    set_val "4000" "$VM"/dirty_writeback_centisecs
    
    # Don't need to set watermark_scale_factor since we already have vm.extra_free_kbytes. See /proc/zoneinfo for more info
    set_val "1" "$VM"/watermark_scale_factor

    # Use multiple threads to run kswapd for better swapping performance
    set_val "8" "$VM"/kswapd_threads
}

write_conf_file()
{
    clear_cfg
    write_cfg "Welcome Back"
    write_cfg ""
    write_cfg "Redmi 10C RAM Management"
    write_cfg "——————————————————"
    write_cfg "Huge Credits to: @yc9559, @helloklf @VR-25, @pedrozzz0, @agnostic-apollo, and other developers"
    write_cfg "Module constructed by free @ Telegram // unintellectual-hypothesis @ GitHub"
    write_cfg "Last time module executed: $(date '+%Y-%m-%d %H:%M:%S')"
    write_cfg "Version: v1.0"
    write_cfg ""
    write_cfg "[ZRAM status]"
    write_cfg "$(zram_status)"
    write_cfg ""
    write_cfg "[FSCC status]"
    write_cfg "$(fscc_status)"
    write_cfg ""
    write_cfg "[Swapfile status]"
    write_cfg "$(swapfile_status)"
    write_cfg ""
    write_cfg "[Settings]"
    write_cfg "# ZRAM Available size (GB): 0 / 0.5 / 1 / 1.5 / 2 / 2.5 / 3 / 4 / 5 / 6 / 8"
    write_cfg "zram_disksize=$zram_disksize"
    write_cfg "# Available compression algorithm: $(get_avail_comp_algo)"
    write_cfg "zram_algo=$zram_algo"
    write_cfg ""
    write_cfg "# Hybrid Swap. Enter 0 to disable hybrid swap or enter 1 to enable hybrid swap"
    write_cfg "enable_hybrid_swap=$enable_hybrid_swap"
    write_cfg ""
    write_cfg "# Swapfile size (GB): 0 / 0.5 / 1 / 1.5 / 2 / 2.5 / 3"
    write_cfg "swapfile_sz=$swapfile_sz"
    write_cfg ""
    if [ "$(zram_wb_support)" -eq 1 ] && [ "$(cat $ZRAM_SYS/backing_dev)" != "none" ]; then
        write_cfg "# ZRAM Writeback app switch threshold, set the minimum number of app switch before performing small ZRAM Writeback. Default is 10 (Recommended 5 ~ 15)"
        write_cfg "app_switch_threshold=$app_switch_threshold"
        write_cfg ""
        write_cfg "# ZRAM Writeback rate. How many seconds before ZRAM activates writeback after switching apps. Default is 10 seconds (Recommended 5 ~ 20)"
        write_cfg "zram_writeback_rate=$zram_writeback_rate"
        write_cfg ""
    fi
    write_cfg "# Dynamic Swappiness: High Load Threshold. Default value is 65 (Recommended value between 50 ~ 75)"
    write_cfg "high_load_threshold=$high_load_threshold"
    write_cfg ""
    write_cfg "# Dynamic Swappiness: Medium Load Threshold. Default value is 30 (Recommended value between 25 ~ 50)"
    write_cfg "medium_load_threshold=$medium_load_threshold"
    write_cfg ""
    write_cfg "# Swappiness rate. How many seconds before changing swappiness. Default is 15 seconds (Recommended 5 ~ 60)"
    write_cfg "swappiness_change_rate=$swappiness_change_rate"
}

# Wait until boot finish
resetprop -w sys.boot_completed 0
sleep 2

# Disable again, because some ROMS activate ZRAM after boot
swap_all_off
zram_reset

wait_until_unlock
conf_zram_param

# Start the rest of the script a little late to run the system first
sleep 10
conf_vm_param
test_swappiness

# Dynamic swappiness & vfs_cache_pressure based on /proc/loadavg
start_dynamic_swappiness

start_auto_zram_writeback
conf_hybrid_swap

change_task_affinity "kswapd"
change_task_affinity "oom_reaper"
change_task_nice "kswapd"
change_task_nice "oom_reaper"

# Start FSCC
"$MODULE_PATH"/system/bin/fscc

# LMKD Minfree Levels, Thanks to helloklf @ GitHub
if [ "$MEM_TOTAL" -le 3145728 ]; then
  resetprop -n sys.lmk.minfree_levels 4096:0,5120:100,8192:200,16384:250,24576:900,39936:950
elif [ "$MEM_TOTAL" -le 4194304 ]; then
  resetprop -n sys.lmk.minfree_levels 4096:0,5120:100,8192:200,24576:250,32768:900,47360:950
elif [ "$MEM_TOTAL" -gt 4194304 ]; then
  resetprop -n sys.lmk.minfree_levels 4096:0,5120:100,8192:200,32768:250,56320:900,71680:950
fi

write_conf_file

exit 0
