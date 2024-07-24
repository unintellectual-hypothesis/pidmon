#!/system/bin/sh
# THANKS TO yc9559 @ GitHub

CONF_FILE="/sdcard/Android/fog_mem_config.txt"
VM="/proc/sys/vm"
ZRAM_DEV="/dev/block/zram0"
ZRAM_SYS="/sys/block/zram0"
SWAP_DIR="/data/lswap"
MI_RAM_EXTENSION_FILE="/data/extm/extm_file"

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
    true > "$CONF_FILE"
}

write_cfg()
{
    echo "$1" >> "$CONF_FILE"
}

read_cfg()
{
    local val=""
    if [ -f "$CONF_FILE" ]; then
        val="$(grep "^$1=" "$CONF_FILE" | head -n 1 | tr -d '' | cut -d= -f2)"
    fi
    echo "$val"
}

wait_until_boot()
{
  until [ "`getprop sys.boot_completed`" == 1 ]; do
    sleep 1
  done
}

# Swap all device
swap_all_off()
{
    for zr in $(cat /proc/swaps | grep "^/" | awk '{print $1}'); do
        toybox swapoff $zr
    done
}

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

get_avail_comp_algo()
{
    # Linux 3.x may not have comp_algorithm tunable
    if [ -f "$ZRAM_SYS/comp_algorithm" ]; then
        # "lz4 [lzo] deflate", remove '[' and ']'
        echo "$(cat $ZRAM_SYS/comp_algorithm | sed "s/\[//g" | sed "s/\]//g")"
    else
        # lzo is the default comp_algorithm since Linux 2.6
        echo "lzo"
    fi
}
