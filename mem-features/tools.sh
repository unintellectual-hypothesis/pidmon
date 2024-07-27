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