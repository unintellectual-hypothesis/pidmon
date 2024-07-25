#!/system/bin/sh

CURR_DIR="$(dirname "$0")"
. "$CURR_DIR"/PATHS.sh

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
