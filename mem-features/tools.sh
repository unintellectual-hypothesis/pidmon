#!/system/bin/sh
# THANKS TO yc9559 @ GitHub
MODDIR=${0%/*}

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
    # Turn off swap partitions
    swap_all_off
    zram_reset
    
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

# Return:status
fscc_status()
{
    # get the correct value after waiting for fscc loading files
    sleep 2
    if [ "$(ps -A | grep fscache-ctrl)" != "" ]; then
        echo "Running. $(cat /proc/meminfo | grep Mlocked | cut -d: -f2 | tr -d ' ') in cache."
    else
        echo "Not running."
    fi
}

# Checks ZRAM Writeback Support
zram_wb_support()
{
    if [ -f "$ZRAM_SYS"/writeback ] && [ -f "$ZRAM_SYS"/backing_dev ] && [ -f "$ZRAM_SYS"/idle ]; then
        echo "1"
    else
        echo "0"
    fi
}

# Configure the Backing Device for ZRAM (Xiaomi RAM Extension)
set_zram_writeback()
{
    if [ "$(zram_wb_support)" -eq 1 ] || [ "$(getprop persist.miui.extm.enable)" -eq "1" ]; then
        loop_device=$(losetup -f)
        loop_num=$(echo "$loop_device" | grep -Eo '[0-9]{1,2}')
        losetup $loop_device /data/extm/extm_file

        set_val "$loop_device" "$ZRAM_SYS"/backing_dev
        set_val "0" "$ZRAM_SYS"/writeback_limit_enable

        # Use "none" as the ZRAM Backing Dev scheduler and turn off iostats to reduce overhead
        set_val none > /sys/block/loop"$loop_num"/queue/scheduler
        set_val 0 > /sys/block/loop"$loop_num"/queue/iostats
    fi
}

# Activate ZRAM
zram_on()
{
    set_val "$3" "$ZRAM_SYS"/comp_algorithm

    if [ "$(zram_wb_support)" -eq 1 ] && [ -f "/data/extm/extm_file" ]; then
        set_zram_writeback
    fi

    set_val "$1" "$ZRAM_SYS"/disksize
    set_val "$2" "$ZRAM_SYS"/mem_limit
    toybox mkswap "$ZRAM_DEV"
    toybox swapon "$ZRAM_DEV" -p 2024

    if [ "$(cat "$ZRAM_SYS"/backing_dev)" != "none" ]; then
        set_val "3" $VM/page-cluster
    else
        set_val "0" $VM/page-cluster
    fi

    # Disable ZRAM readahead
    set_val "0" "$ZRAM_SYS"/read_ahead_kb

    # Use memory deduplication for ZRAM
    set_val 1 "$ZRAM_SYS"/use_dedup

    if [ "$(read_cfg enable_hybrid_swap)" -eq 0 ]; then
        set_val "false" /sys/kernel/mm/swap/vma_ra_enabled
    fi
}

zram_get_comp_alg()
{
    local str
    str="$(cat "$ZRAM_SYS"/comp_algorithm)"
    echo "$str"
}

get_avail_comp_algo()
{
    echo "$(cat "$ZRAM_SYS"/comp_algorithm | sed "s/\[//g" | sed "s/\]//g")"
}

zram_reset()
{
  set_val "1" "$ZRAM_SYS"/reset
}

zram_status()
{
    local swap_info
    swap_info="$(cat /proc/swaps | grep "$ZRAM_DEV")"
    if [ "$swap_info" != "" ]; then
        echo "Enabled. Size $(echo "$swap_info" | awk '{print $3}')kB, using $(zram_get_comp_alg)."
    else
        echo "Disabled by user."
    fi
}