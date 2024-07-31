#!/system/bin/sh
# Constructed by: free @ Telegram // unintellectual-hypothesis @GitHub
MODDIR=${0%/*}
MEM_TOTAL="$(awk '/^MemTotal:/{print $2}' /proc/meminfo)"

# Set Original Module Directory
MODULE_PATH="$(dirname $(readlink -f "$0"))"
MODULE_PATH="${MODULE_PATH%/variants}"

# load libraries
MEM_FEATURES_DIR="$MODULE_PATH/mem-features"
. "$MEM_FEATURES_DIR"/tools.sh
. "$MEM_FEATURES_DIR"/conf_mi_reclaim.sh
. "$MEM_FEATURES_DIR"/hybrid_swap.sh
. "$MEM_FEATURES_DIR"/kswapd_oom_aff.sh

# According to function
zram_disksize=""
zram_algo=""

conf_zram_param()
{
    # load size from file
    zram_disksize="$(read_cfg zram_disksize)"
    case "$zram_disksize" in
        0|0.5|1|1.5|2|2.5|3|4|5|6|8) ;;
        *) zram_disksize=2.5 ;;
    esac

    # load algorithm from file, use lz4 as default
    zram_algo="$(read_cfg zram_algo)"
    [ "$zram_algo" == "" ] && zram_algo="lz4"

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
        3.5)  zram_on 3584M 1260M "$zram_algo" ;;
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
            *) swapfile_sz=1 ;;
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
    set_val "8" "$VM"/dirty_background_ratio
    set_val "76800" "$VM"/extra_free_kbytes
    set_val "3000" "$VM"/dirty_expire_centisecs
    set_val "4500" "$VM"/dirty_writeback_centisecs
    
    # Don't need to set watermark_scale_factor since we already have vm.extra_free_kbytes. See /proc/zoneinfo for more info
    set_val "1" "$VM"/watermark_scale_factor

    # Use multiple threads to run kswapd for better swapping performance
    set_val "8" "$VM"/kswapd_threads
    
    # Fair
    set_val "100" "$VM"/vfs_cache_pressure
    
    # Set higher swappiness for ZRAM
    if [ "$(cat /proc/swaps | grep "$ZRAM_DEV")" != "" ]; then
        set_val "160" "$VM"/swappiness
        set_val "160" /dev/memcg/memory.swappiness
        set_val "160" /dev/memcg/apps/memory.swappiness
        set_val "160" /dev/memcg/system/memory.swappiness
    else
        set_val "100" "$VM"/swappiness
        set_val "100" /dev/memcg/memory.swappiness
        set_val "100" /dev/memcg/apps/memory.swappiness
        set_val "100" /dev/memcg/system/memory.swappiness
    fi
}

write_conf_file()
{
    clear_cfg
    write_cfg "Welcome Back"
    write_cfg ""
    write_cfg "Redmi 10/10C/10 Power Memory Management Optimization"
    write_cfg "———————————————————————————————————"
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
    write_cfg "# Please reboot device everytime the configuration is changed"
    write_cfg ""
    write_cfg "# ZRAM Available size (GB): 0 / 0.5 / 1 / 1.5 / 2 / 2.5 / 3 / 3.5 / 4 / 5 / 6 / 8"
    write_cfg "zram_disksize=$zram_disksize"
    write_cfg "# Available compression algorithm: $(get_avail_comp_algo)"
    write_cfg "zram_algo=$zram_algo"
    write_cfg ""
    write_cfg "# Hybrid Swap. Enter 0 to disable hybrid swap or enter 1 to enable hybrid swap"
    write_cfg "enable_hybrid_swap=$enable_hybrid_swap"
    write_cfg ""
    write_cfg "# Swapfile size (GB): 0 / 0.5 / 1 / 1.5 / 2 / 2.5 / 3"
    write_cfg "swapfile_sz=$swapfile_sz"
    if [ "$(zram_wb_support)" -eq 1 ] && [ "$(cat "$ZRAM_SYS"/backing_dev)" != "none" ]; then
        write_cfg ""
        write_cfg "# ZRAM Writeback: App Switch Threshold, set the minimum number of app switch before performing small ZRAM Writeback. Default is 10 (Recommended 5 ~ 15)"
        write_cfg "app_switch_threshold=$app_switch_threshold"
        write_cfg ""
        write_cfg "# ZRAM Writeback: Writeback Rate. How many seconds before ZRAM activates writeback after switching apps. Default is 10 seconds (Recommended 5 ~ 20)"
        write_cfg "zram_writeback_rate=$zram_writeback_rate"
    fi
    write_cfg ""
    write_cfg "# Dynamic Swappiness and VFS Cache Pressure based on /proc/loadavg"
    write_cfg "enable_dynamic_mem_system=$enable_dynamic_mem_system"
    if [ "$(read_cfg enable_dynamic_mem_system)" == "1" ]; then
        write_cfg ""
        write_cfg "# Dynamic Swappiness: High Load Threshold. Default value is 65 (Recommended value between 50 ~ 75)"
        write_cfg "high_load_threshold=$high_load_threshold"
        write_cfg ""
        write_cfg "# Dynamic Swappiness: Medium Load Threshold. Default value is 25 (Recommended value between 25 ~ 50)"
        write_cfg "medium_load_threshold=$medium_load_threshold"
        write_cfg ""
        write_cfg "# Dynamic Swappiness: Swappiness Change Rate. How many seconds before changing swappiness. Default is 15 seconds (Recommended 5 ~ 60)"
        write_cfg "swappiness_change_rate=$swappiness_change_rate"
    fi
    if [ -d "/sys/kernel/mi_reclaim" ] || [ -d "/d/rtmm" ] || [ -d "/sys/kernel/mm/rtmm" ]; then
        write_cfg ""
        write_cfg "# Mi reclaim. Set value to 0 to turn off and 1 to turn on"
        write_cfg "mi_reclaim=$mi_reclaim"
    fi
    write_cfg ""
}

# Disable all swap partitions before finish booting
swap_all_off

# Wait until boot finish
resetprop -w sys.boot_completed 0

# We must wait until device is unlocked, or we can't write to /sdcard
wait_until_unlock

# Load default config values
app_switch_threshold="$(read_cfg app_switch_threshold)"
[ "$app_switch_threshold" == "" ] && app_switch_threshold="10"
zram_writeback_rate="$(read_cfg zram_writeback_rate)"
[ "$zram_writeback_rate" == "" ] && zram_writeback_rate="10"
high_load_threshold="$(read_cfg high_load_threshold)"
[ "$high_load_threshold" == "" ] && high_load_threshold="65"
medium_load_threshold="$(read_cfg medium_load_threshold)"
[ "$medium_load_threshold" == "" ] && medium_load_threshold="25"
swappiness_change_rate="$(read_cfg swappiness_change_rate)"
[ "$swappiness_change_rate" == "" ] && swappiness_change_rate="10"
enable_dynamic_mem_system="$(read_cfg enable_dynamic_mem_system)"
[ "$enable_dynamic_mem_system" == "" ] && enable_dynamic_mem_system="1"

# Configure ZRAM
conf_zram_param

# Start the rest of the script a little late to avoid collisions
sleep 10

# Configure virtual machine parameters
conf_vm_param

# Start dynamic swappiness
if [ "$enable_dynamic_mem_system" == 1 ]; then
        "$MODULE_PATH"/system/bin/dynamic_mem &
fi

# Start intelligent ZRAM writeback
if [ "$(zram_wb_support)" -eq 1 ] && [ "$(cat "$ZRAM_SYS"/backing_dev)" != "none" ]; then
        "$MODULE_PATH"/system/bin/intelligent_zram_writeback &
fi

# Initialize hybrid swap setup, if enabled
setup_hybrid_swap

# Change affinity of kswapd and oom_reaper
change_task_affinity "kswapd"
change_task_affinity "oom_reaper"
change_task_nice "kswapd"
change_task_nice "oom_reaper"

# Configure mi_reclaim
conf_mi_reclaim

# Start Filesystem Cache Control and wait for a minute
"$MODULE_PATH"/system/bin/fscc &

# Configuration file in /sdcard/Android/fog_mem_config.txt
write_conf_file

# Optimize LMKD Minfree Levels for 4GB, Thanks to helloklf @ GitHub
resetprop -n sys.lmk.minfree_levels 4096:0,5120:100,8192:200,24576:250,32768:900,47360:950

# Set higher CUR_MAX_CACHED_PROCESSES for 4GB
/system/bin/device_config put activity_manager max_cached_processes 64

exit 0
