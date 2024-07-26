#!/system/bin/sh
MODDIR=${0%/*}

CFG_FILE="/sdcard/Android/fog_mem_config.txt"
VM="/proc/sys/vm"
ZRAM_DEV="/dev/block/zram0"
ZRAM_SYS="/sys/block/zram0"
SWAP_DIR="/data/lswap"
