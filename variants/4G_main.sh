#!/system/bin/sh
MODULE_PATH="/data/adb/modules/fog-mem-opt"

# load libraries
MEM_FT_DIR="$MODULE_PATH/mem-features"
. "$MEM_FT_DIR"/TOOLS.sh
. "$MEM_FT_DIR"/dynamic_swappiness.sh
. "$MEM_FT_DIR"/intelligent_zram_writeback.sh
. "$MEM_FT_DIR"/lswap_conf.sh
. "$MEM_FT_DIR"/kswapd_oom_affinity.sh
. "$MODDIR"/bin/fscc

zram_algo=""
zram_avail_algo="$(get_avail_comp_algo)"
zram_disksize=""
enable_hybrid_swap=""
swap_over_hundy=0

# Test if kernel supports swappiness over 100 (Some ROM defaults swappiness to 100)
test_swappiness()
{
  set_value "160" "$VM"/swappiness
  new_swappiness=$(cat "$VM"/swappiness)
  if [ "$new_swappiness" -eq 160 ]; then
    swap_over_hundy=1
  else
    swap_over_hundy=0
  fi
}

conf_zram_param()
{
    # load size from file
    zram_disksize="$(read_cfg zram_disksize)"
    case "$zram_disksize" in
        0.0|0|0.5|1.0|1|1.5|2.0|2|2.5|3.0|3|4.0|4|5.0|5|6.0|6|8.0|8) ;;
        *) zram_disksize=2.5 ;;
    esac

    # load algorithm from file, use lz0 as default
    zram_algo="$(read_cfg zram_algo)"
    [ "$zram_algo" == "" ] && zram_algo="lz0"

    # ~2.8x compression ratio
    # higher disksize result in larger space-inefficient SwapCache
    case "$zram_disksize" in
        0.0|0)  swap_all_off ;;
        0.5)    zram_on 512M 160M "$zram_algo" ;;
        1.0|1)  zram_on 1024M 360M "$zram_algo" ;;
        1.5)    zram_on 1536M 540M "$zram_algo" ;;
        2.0|2)  zram_on 2048M 720M "$zram_algo" ;;
        2.5)    zram_on 2560M 900M "$zram_algo" ;;
        3.0|3)  zram_on 3072M 1080M "$zram_algo" ;;
        4.0|4)  zram_on 4096M 1440M "$zram_algo" ;;
        5.0|5)  zram_on 5120M 1800M "$zram_algo" ;;
        6.0|6)  zram_on 6144M 2160M "$zram_algo" ;;
        8.0|8)  zram_on 8192M 2880M "$zram_algo" ;;

    esac
}

conf_hybrid_swap()
{
    enable_hybrid_swap="$(read_cfg enable_hybrid_swap)"
    [ "$enable_hybrid_swap" == "" ] && enable_hybrid_swap=0

    if [ "$(read_cfg enable_hybrid_swap)" -eq 1 ]; then
        if [ -f "$SWAP_DIR"/swapfile ]; then
            toybox swapon -d "$SWAP_DIR"/swapfile -p 1111
        else
            mkdir "$SWAP_DIR"
            dd if=/dev/zero of="$SWAP_DIR"/swapfile bs=1M count=1024
            toybox mkswap "$SWAP_DIR"/swapfile
            toybox swapon -d "$SWAP_DIR"/swapfile -p 1111
        fi

        # Enable Qualcomm's Per-Process Reclaim for Hybrid Swap Setup IF AND ONLY IF, ZRAM and Swapfile are on at the same time
        if [ "$(read_cfg zram_disksize)" != "0" ] || [ "$(read_cfg zram_disksize)" != "0.0" ]; then
            set_val "1" /sys/module/process_reclaim/parameters/enable_process_reclaim
            set_val "90" /sys/module/process_reclaim/parameters/pressure_max
            set_val "70" /sys/module/process_reclaim/parameters/pressure_min
            set_val "256" /sys/module/process_reclaim/parameters/per_swap_size
        fi
    fi
}

conf_vm_param()
{
    set_val "15" "$VM"/dirty_ratio
    set_val "3" "$VM"/dirty_background_ratio
    set_val "102400" "$VM"/extra_free_kbytes

    # Don't need to set watermark_scale_factor since we already have vm.extra_free_kbytes. See /proc/zoneinfo for more info
    set_val "1" "$VM"/watermark_scale_factor

    set_val "8192" "$VM"/min_free_kbytes
    set_val "0" "$VM"/direct_swappiness
    set_val "4000" "$VM"/dirty_writeback_centisecs

    # Use multiple threads to run kswapd for better swapping performance
    set_val "8" "$VM"/kswapd_threads
}

write_conf_file()
{
    clear_cfg
    write_cfg ""
    write_cfg "Welcome Back"
    write_cfg ""
    write_cfg "Redmi 10C RAM Management"
    write_cfg "------------------------"
    write_cfg "Thanks to: @yc9559, @VR-25, @pedrozzz0, and other developers"
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
    write_cfg "# ZRAM Available size(GB): 0 / 0.5 / 1 / 1.5 / 2 / 2.5 / 3 / 4 / 5 / 6 / 8"
    write_cfg "zram_size=$zram_size"
    write_cfg "# Available compression algorithm: $zram_avail_algo"
    write_cfg "zram_algo=$zram_algo"
    write_cfg ""
    write_cfg "# Hybrid Swap (System will use swapfile when ZRAM is exhausted). Enter 0 to disable hybrid swap or enter 1 to enable hybrid swap"
    write_cfg "enable_hybrid_swap=$enable_hybrid_swap"
    write_cfg ""
    if [ "$(zram_writeback_support)" -eq 1 ]; then
        write_cfg "# ZRAM Writeback, set the minimum number of app switch before performing small ZRAM Writeback "
        write_cfg "app_switch_threshold=$app_switch_threshold"
        write_cfg ""
    fi
    write_cfg "# Dynamic Swappiness. Change the values below between 0 ~ 100."
    write_cfg ""
    write_cfg "# High Load Threshold. Default value is 50 (Recommended value between 50 ~ 75)"
    write_cfg "high_load_threshold=$high_load_threshold"
    write_cfg ""
    write_cfg "# Medium Load Threshold. Default value is 25 (Recommended value between 25 ~ 50)"
    write_cfg "medium_load_threshold=$medium_load_threshold"
    write_cfg ""
}

swap_all_off

# Wait until boot finish
wait_until_boot

swap_all_off
conf_zram_param
conf_hybrid_swap
test_swappiness
start_dynamic_swappiness

sleep 15
conf_vm_param

change_task_affinity "kswapd"
change_task_affinity "oom_reaper"
change_task_nice "kswapd"
change_task_nice "oom_reaper"

# Perform Intelligent Auto ZRAM Writeback
auto_zram_writeback

# Run FSCC (similar to Android's PinnerService, Mlock(Unevictable) 200~350MB)
fscc_stop
fscc_start

write_conf_file

exit 0
