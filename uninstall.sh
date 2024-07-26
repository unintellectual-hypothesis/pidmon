#!/system/bin/sh

# Ensure the module path is deleted
rm -rf "$MODPATH"

# Remove swapfile
rm -rf "data/lswap"

# Wait until write is permissible on /sdcard
while [ ! -d "/sdcard/Android" ]; do
  sleep 1
done

# Remove config file
rm -rf "/sdcard/Android/fog_mem_config.txt"
