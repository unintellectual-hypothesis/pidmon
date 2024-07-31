#!/system/bin/sh
# All the code belongs to helloklf @ GitHub
MODDIR=${0%/*}

# Load libraries 
MEM_FEATURES_DIR="$MODULE_PATH/mem-features"
. "$MEM_FEATURES_DIR"/paths.sh

mi_reclaim=""

conf_mi_reclaim() {
    mi_reclaim="$(read_cfg mi_reclaim)"
    [ "$mi_reclaim" == "" ] && mi_reclaim=1

    if [[ "$mi_reclaim" == "0" ]]; then
        set_val "0" /sys/kernel/mi_reclaim/enable

        mi_rtmm=""
        if [[ -d "/d/rtmm" ]]; then
        mi_rtmm="/d/rtmm/reclaim"
        elif [[ -d "/sys/kernel/mm/rtmm" ]]; then
        mi_rtmm="/sys/kernel/mm/rtmm"
        else
        return
        fi
        chmod 000 "$mi_rtmm"/reclaim/auto_reclaim 2>/dev/null
        chown root:root "$mi_rtmm"/reclaim/auto_reclaim 2>/dev/null
        chmod 000 "$mi_rtmm"/reclaim/global_reclaim 2>/dev/null
        chown root:root "$mi_rtmm"/reclaim/global_reclaim 2>/dev/null
        chmod 000 "$mi_rtmm"/reclaim/proc_reclaim 2>/dev/null
        chown root:root "$mi_rtmm"/reclaim/proc_reclaim 2>/dev/null
        chmod 000 "$mi_rtmm"/reclaim/kill 2>/dev/null
        chown root:root "$mi_rtmm"/reclaim/kill 2>/dev/null
        chown root:root "$mi_rtmm"/compact/compact_memory 2>/dev/null
  fi
}