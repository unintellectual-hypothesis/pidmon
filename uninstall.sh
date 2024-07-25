#!/system/bin/sh

rm -rf "data/lswap/swapfile"

# Wait until write is permissible on /sdcard
while [ ! -d "/sdcard/Android" ]; do
  sleep 1
done

rm -rf "/sdcard/Android/fog_mem_config.txt"
