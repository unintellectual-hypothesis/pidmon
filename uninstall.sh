#!/system/bin/sh

while [ ! -d "/sdcard/Android" ]; do
  sleep 1
done

rm -rf "/sdcard/Android/fog_mem_config.txt"
