#!/system/bin/sh
MODDIR=${0%/*}
MEM_TOTAL="$(awk '/^MemTotal:/{print $2}' /proc/meminfo)"

# LMKD Optimization
resetprop -n ro.lmk.use_new_strategy 1
resetprop -n ro.lmk.thrashing_min_score_adj 0
resetprop -n ro.lmk.low 1001
resetprop -n ro.lmk.medium 1001
resetprop -n ro.lmk.critical 1001
resetprop -n ro.lmk.swap_free_low_percentage 10
resetprop -n ro.lmk.enhance_batch_kill false
resetprop -n ro.lmk.enable_adaptive_lmk false
resetprop -n ro.lmk.use_minfree_levels false
resetprop -n ro.lmk.critical_upgrade true
resetprop -n ro.lmk.upgrade_pressure 100
resetprop -n ro.lmk.downgrade_pressure 100
resetprop -n ro.lmk.kill_heaviest_task false
resetprop -n ro.lmk.kill_timeout_ms 30
resetprop -n ro.lmk.use_psi true
resetprop -n ro.lmk.psi_partial_stall_ms 750
resetprop -n ro.lmk.psi_complete_stall_ms 1400
resetprop -n ro.lmk.swap_util_max 100
resetprop -n ro.lmk.thrashing_limit 30
resetprop -n ro.lmk.thrashing_limit_decay 50
resetprop -p --delete persist.device_config.lmkd_native.thrashing_limit_critical
resetprop -p --delete lmkd.reinit

# LMKD Minfree Levels, Thanks to helloklf @ GitHub
if [ "$MEM_TOTAL" -le 3145728 ]; then
  resetprop -n sys.lmk.minfree_levels 4096:0,5120:100,8192:200,16384:250,24576:900,39936:950
elif [ "$MEM_TOTAL" -le 4194304 ]; then
  resetprop -n sys.lmk.minfree_levels 4096:0,5120:100,8192:200,24576:250,32768:900,47360:950
elif [ "$MEM_TOTAL" -gt 4194304 ]; then
  resetprop -n sys.lmk.minfree_levels 4096:0,5120:100,8192:200,32768:250,56320:900,71680:950
fi


# I/O Optimization for UFS
for queue in /sys/block/dm*/queue
do
  echo noop > $queue/scheduler
done

for queue in /sys/block/mmc*/queue
do
  echo 0 > $queue/read_ahead_kb
done
