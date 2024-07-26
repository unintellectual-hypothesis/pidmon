MODDIR=${0%/*}
VAR_DIR="$MODDIR/variants"
MEM_TOTAL="$(awk '/^MemTotal:/{print $2}' /proc/meminfo)"

# log
LOG_FILE=$MODDIR/fog_mem_debug.log
exec 2>$LOG_FILE
set -x

# Automatic Script Execution for  3GB/4GB/6GB variants
if [ "$MEM_TOTAL" -le 3145728 ]; then
    sh "$VAR_DIR"/3G_main.sh
elif [ "$MEM_TOTAL" -le 4197304 ]; then
    sh "$VAR_DIR"/4G_main.sh
elif [ "$MEM_TOTAL" -gt 4197304 ]; then
    sh "$VAR_DIR"/6G_more_main.sh
fi
