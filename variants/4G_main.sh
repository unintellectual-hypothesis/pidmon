#!/system/bin/sh
# Constructed by: free @ Telegram // unintellectual-hypothesis @GitHub
MODDIR=${0%/*}

# Set Original Module Directory
MODULE_PATH="$(dirname $(readlink -f "$0"))"
MODULE_PATH="${MODULE_PATH%/variants}"

# load libraries
MEM_FEATURES_DIR="$MODULE_PATH/mem-features"
. "$MEM_FEATURES_DIR"/tools.sh
. "$MEM_FEATURES_DIR"/dynamic_swappiness.sh
. "$MEM_FEATURES_DIR"/hybrid_swap.sh
. "$MEM_FEATURES_DIR"/intelligent_zram_writeback.sh
. "$MEM_FEATURES_DIR"/kswapd_oom_aff.sh

zram_disksize=""
zram_algo=""

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


# Disable all swap partitions
swap_all_off
zram_reset

# We must wait until device is unlocked, or we can't write to /sdcard
wait_until_unlock

# Configure ZRAM
conf_zram_param

# Start the rest of the script a little late to avoid collisions
sleep 10

# Configure virtual machine parameters
conf_vm_param

# Test if system supports swappiness > 100
test_swappiness

# Start dynamic swappiness
start_dynamic_swappiness

# Start intelligent ZRAM writeback
start_auto_zram_writeback

# Initialize hybrid swap setup, if enabled
setup_hybrid_swap

# Change affinity of kswapd and oom_reaper
change_task_affinity "kswapd"
change_task_affinity "oom_reaper"
change_task_nice "kswapd"
change_task_nice "oom_reaper"

# Start Filesystem Cache Control
"$MEM_FEATURES_DIR"/fscc.sh

# LMKD Minfree Levels, Thanks to helloklf @ GitHub

