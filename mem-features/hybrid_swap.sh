#!/system/bin/sh
MODDIR=${0%/*}

# Load libraries 
MEM_FEATURES_DIR="$MODULE_PATH/mem-features"
. "$MEM_FEATURES_DIR"/paths.sh

enable_hybrid_swap=""
swapfile_size=""

swapfile_status()
{
    local swap_info
    swap_info="$(cat /proc/swaps | grep "$SWAP_DIR/swapfile")"
    if [ "$swap_info" != "" ] && [ "$(read_cfg zram_disksize)" != "0" ] || [ "$(read_cfg zram_disksize)" != "0.0" ]; then
        echo "Hybrid Swap Enabled. Size $(echo "$swap_info" | awk '{print $3}')kB."
    elif [ "$swap_info" != "" ]; then
        echo "Swapfile Enabled, ZRAM Disabled. Size $(echo "$swap_info" | awk '{print $3}')kB. Disabled Qualcomm's PPR"
    else
        echo "Disabled by user."
    fi
}

conf_hybrid_swap()
{
    enable_hybrid_swap="$(read_cfg enable_hybrid_swap)"
    [ "$enable_hybrid_swap" == "" ] && enable_hybrid_swap=0
    swapfile_size="$(read_cfg swapfile_size)"
    case "$swapfile_size" in
        0|0.5|1|1.5|2|2.5|3) ;;
        *) swapfile_size=1 ;;
    esac

    if [ "$enable_hybrid_swap" -eq 1 ]; then
        if [ -f "$SWAP_DIR"/swapfile ]; then
            toybox swapon -d "$SWAP_DIR"/swapfile -p 1111
        else
            mkdir "$SWAP_DIR"
            dd if=/dev/zero of="$SWAP_DIR"/swapfile bs=1M count=32
            toybox mkswap "$SWAP_DIR"/swapfile
            toybox swapon -d "$SWAP_DIR"/swapfile -p 1111
        fi

        # Enable Qualcomm's Per-Process Reclaim for Hybrid Swap Setup IF AND ONLY IF, ZRAM and Swapfile are on at the same time
        if [ "$(read_cfg zram_disksize)" != "0" ]; then
            set_val "1" /sys/module/process_reclaim/parameters/enable_process_reclaim
            set_val "90" /sys/module/process_reclaim/parameters/pressure_max
            set_val "70" /sys/module/process_reclaim/parameters/pressure_min
            set_val "256" /sys/module/process_reclaim/parameters/per_swap_size
        fi
    fi
}