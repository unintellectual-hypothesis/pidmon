#!/system/bin/sh
MODDIR=${0%/*}

# Load libraries 
MEM_FEATURES_DIR="$MODULE_PATH/mem-features"
. "$MEM_FEATURES_DIR"/paths.sh

enable_hybrid_swap=""
swapfile_sz=""
PPR="/sys/module/process_reclaim/parameters"

swapfile_status()
{
    local swap_info
    swap_info="$(cat /proc/swaps | grep "$SWAP_DIR/swapfile")"
    if [ "$swap_info" != "" ] && [ "$(read_cfg zram_disksize)" != "0" ]; then
        echo "Hybrid Swap Enabled. Size $(echo "$swap_info" | awk '{print $3}')kB."
    elif [ "$swap_info" != "" ]; then
        echo "Swapfile Enabled, ZRAM Disabled. Size $(echo "$swap_info" | awk '{print $3}')kB. Disabled Qualcomm's PPR"
    else
        echo "Disabled by user."
    fi
}

swapfile_on()
{
    if [ -f "$SWAP_DIR"/swapfile ]; then
        toybox swapon -d "$SWAP_DIR"/swapfile -p 1111
    else
        mkdir "$SWAP_DIR"
        dd if=/dev/zero of="$SWAP_DIR"/swapfile bs=1M count="$1"
        toybox mkswap "$SWAP_DIR"/swapfile
        toybox swapon -d "$SWAP_DIR"/swapfile -p 1111
    fi

        # Enable Qualcomm's Per-Process Reclaim for Hybrid Swap Setup IF AND ONLY IF, ZRAM and Swapfile are on at the same time
    if [ "$(read_cfg zram_disksize)" != "0" ]; then
        set_val "1" "$PPR"/enable_process_reclaim
        set_val "90" "$PPR"/pressure_max
        set_val "70" "$PPR"/pressure_min
        if [ "$MEM_TOTAL" -le 3145728 ]; then
            set_val "128" "$PPR"/per_swap_size
        elif [ "$MEM_TOTAL" -le 4197304 ]; then
            set_val "256" "$PPR"/per_swap_size
        elif [ "$MEM_TOTAL" -gt 4197304 ]; then
            set_val "512" "$PPR"/per_swap_size
        fi
    fi
}
