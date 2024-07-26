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

conf_zram_param()
{
    # load size from file
    zram_disksize="$(read_cfg zram_disksize)"
    case "$zram_disksize" in
        0|0.5|1|1.5|2|2.5|3|4|5|6|8) ;;
        *) zram_disksize=4 ;;
    esac

    # load algorithm from file, use lz0 as default
    zram_algo="$(read_cfg zram_algo)"
    [ "$zram_algo" == "" ] && zram_algo="lz0"

    # ~2.8x compression ratio
    # higher disksize result in larger space-inefficient SwapCache
    case "$zram_disksize" in
        0)  swap_all_off ;;
        0.5)  zram_on 512M 160M "$zram_algo" ;;
        1)  zram_on 1024M 360M "$zram_algo" ;;
        1.5)  zram_on 1536M 540M "$zram_algo" ;;
        2)  zram_on 2048M 720M "$zram_algo" ;;
        2.5)  zram_on 2560M 900M "$zram_algo" ;;
        3)  zram_on 3072M 1080M "$zram_algo" ;;
        4)  zram_on 4096M 1440M "$zram_algo" ;;
        5)  zram_on 5120M 1800M "$zram_algo" ;;
        6)  zram_on 6144M 2160M "$zram_algo" ;;
        8)  zram_on 8192M 2880M "$zram_algo" ;;
    esac
}

setup_hybrid_swap()
{
    enable_hybrid_swap="$(read_cfg enable_hybrid_swap)"
    [ "$enable_hybrid_swap" == "" ] && enable_hybrid_swap=0

    # Load size from config file
    swapfile_sz="$(read_cfg swapfile_sz)"
    [ "$swapfile_sz" == "" ] && swapfile_sz=0

    if [ "$enable_hybrid_swap" -eq 1 ]; then
        case "$swapfile_sz" in
            0|0.5|1|1.5|2|2.5|3) ;;
            *) swapfile_sz=2 ;;
        esac

        case "$swapfile_sz" in
            0)  swap_all_off ;;
            0.5)  swapfile_on 512 ;;
            1)  swapfile_on 1024 ;;
            1.5)  swapfile_on 1536 ;;
            2)  swapfile_on 2048 ;;
            2.5)  swapfile_on 2560 ;;
            3)  swapfile_on 3072 ;;
        esac
    fi
}

conf_vm_param()
{
    set_val "15" "$VM"/dirty_ratio
    set_val "10" "$VM"/dirty_background_ratio
    set_val "102400" "$VM"/extra_free_kbytes
    set_val "12288" "$VM"/min_free_kbytes
    set_val "3000" "$VM"/dirty_expire_centisecs
    set_val "5000" "$VM"/dirty_writeback_centisecs
    
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
    write_cfg "Redmi 10/10C/10 Power Memory Management Optimization"
    write_cfg "——————————————————————————————————"
    write_cfg "Huge Credits to: @yc9559, @helloklf @VR-25, @pedrozzz0, @agnostic-apollo, and other developers"
    write_cfg "Module constructed by free @ Telegram // unintellectual-hypothesis @ GitHub"
    write_cfg "Last time module executed: $(date '+%Y-%m-%d %H:%M:%S')"
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
    if [ "$(zram_wb_support)" -eq 1 ] && [ "$(cat "$ZRAM_SYS"/backing_dev)" != "none" ]; then
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
sleep 2.5

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
"$MODULE_PATH"/system/bin/fscc

# Optimize LMKD Minfree Levels, Thanks to helloklf @ GitHub
if [ "$MEM_TOTAL" -le 3145728 ]; then
    resetprop -n sys.lmk.minfree_levels 4096:0,5120:100,8192:200,16384:250,24576:900,39936:950
elif [ "$MEM_TOTAL" -le 4194304 ]; then
    resetprop -n sys.lmk.minfree_levels 4096:0,5120:100,8192:200,24576:250,32768:900,47360:950
elif [ "$MEM_TOTAL" -gt 4194304 ]; then
    resetprop -n sys.lmk.minfree_levels 4096:0,5120:100,8192:200,32768:250,56320:900,71680:950
fi

# Configuration file in /sdcard/Android/fog_mem_config.txt
write_conf_file

sleep 300
# Optimize LMKD Minfree Levels, Thanks to helloklf @ GitHub
if [ "$MEM_TOTAL" -le 3145728 ]; then
    resetprop -n sys.lmk.minfree_levels 4096:0,5120:100,8192:200,16384:250,24576:900,39936:950
elif [ "$MEM_TOTAL" -le 4194304 ]; then
    resetprop -n sys.lmk.minfree_levels 4096:0,5120:100,8192:200,24576:250,32768:900,47360:950
elif [ "$MEM_TOTAL" -gt 4194304 ]; then
    resetprop -n sys.lmk.minfree_levels 4096:0,5120:100,8192:200,32768:250,56320:900,71680:950
fi

# Set higher CUR_MAX_CACHED_PROCESSES
if [ "$MEM_TOTAL" -gt 4194304 ]; then
    /system/bin/device_config put activity_manager max_cached_processes 128
else
    /system/bin/device_config put activity_manager max_cached_processes 64
fi

exit 0
