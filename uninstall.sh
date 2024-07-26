#!/system/bin/sh

# Remove swapfile
rm -rf "data/lswap/swapfile"

# Wait until write is permissible on /sdcard
while [ ! -d "/sdcard/Android" ]; do
  sleep 1
done

# Remove config file
rm -rf "/sdcard/Android/fog_mem_config.txt"
