#!/system/bin/sh
# THANKS TO yc9559 @ GitHub

CURR_DIR="$(dirname "$0")"
. "$CURR_DIR"/PATHS.sh

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
    local val=""
    if [ -f "$CFG_FILE" ]; then
        val="$(grep "^$1=" "$CFG_FILE" | head -n 1 | tr -d '' | cut -d= -f2)"
    fi
    echo "$val"
}

wait_until_boot()
{
  resetprop -w sys.boot_completed 0
}

# Swapoff all device
swap_all_off()
{
    for zr in $(cat /proc/swaps | grep "^/" | awk '{print $1}'); do
        $TB swapoff "$zr"
    done
}

get_avail_comp_algo()
{
    # Linux 3.x may not have comp_algorithm tunable
    if [ -f "$ZRAM_SYS/comp_algorithm" ]; then
        # "lz4 [lzo] deflate", remove '[' and ']'
        echo "$(cat "$ZRAM_SYS"/comp_algorithm | sed "s/\[//g" | sed "s/\]//g")"
    else
        # lzo is the default comp_algorithm since Linux 2.6
        echo "lzo"
    fi
}
