#!/usr/bin/env bash
# =============================================================================
# ping_monitor.sh — Router Restart Monitor
# Platform : Ubuntu 24.04 LTS (container or VM on any Linux host)
# Author   : t-philip / Claude
# Version  : 1.0
# =============================================================================

# --- Configuration -----------------------------------------------------------
LAN_TARGET="192.168.1.1"
WAN_TARGET_1="8.8.8.8"
WAN_TARGET_2="1.1.1.1"
PING_INTERVAL=30
FAILURE_THRESHOLD=3
# Fixed path, not $HOME -- this runs as a dedicated non-root service user with no
# home directory (see ping_monitor.service and the README's Setup section).
LOG_DIR="/var/log/ping_monitor"
LOG_FILE="$LOG_DIR/ping_monitor.log"
# -----------------------------------------------------------------------------

mkdir -p "$LOG_DIR"

if [[ ! -s "$LOG_FILE" ]]; then
    echo "timestamp,event,target_type,target_ip,duration_min,probable_restart" \
        >> "$LOG_FILE"
fi

lan_fail_count=0
wan_fail_count=0
lan_outage_start=""
wan_outage_start=""
lan_in_outage=false
wan_in_outage=false

day_outage_count=0
day_total_downtime=0
current_day=$(date +%Y-%m-%d)

log() {
    local ts event ttype tip dur pr
    ts=$(date "+%Y-%m-%d %H:%M:%S")
    event="$1"; ttype="$2"; tip="$3"; dur="${4:-}"; pr="${5:-}"
    echo "${ts},${event},${ttype},${tip},${dur},${pr}" >> "$LOG_FILE"
}

log_daily_summary() {
    local ts
    ts=$(date "+%Y-%m-%d 23:59:59")
    echo "${ts},DAILY_SUMMARY,,,${day_total_downtime}," >> "$LOG_FILE"
    day_outage_count=0
    day_total_downtime=0
}

ping_host() {
    ping -c 1 -W 3 "$1" > /dev/null 2>&1
}

echo "$(date "+%Y-%m-%d %H:%M:%S"),MONITOR_START,,,,$(hostname)" >> "$LOG_FILE"

while true; do

    now_day=$(date +%Y-%m-%d)

    if [[ "$now_day" != "$current_day" ]]; then
        log_daily_summary
        current_day="$now_day"
    fi

    if ping_host "$LAN_TARGET"; then
        if $lan_in_outage; then
            outage_end=$(date +%s)
            outage_start_epoch=$(date -d "$lan_outage_start" +%s)
            duration_min=$(( (outage_end - outage_start_epoch) / 60 ))
            [[ $duration_min -lt 1 ]] && duration_min=1
            log "OUTAGE_END" "LAN" "$LAN_TARGET" "$duration_min" "yes"
            day_outage_count=$((day_outage_count + 1))
            day_total_downtime=$((day_total_downtime + duration_min))
            lan_in_outage=false
            lan_outage_start=""
        fi
        lan_fail_count=0
    else
        lan_fail_count=$((lan_fail_count + 1))
        if [[ $lan_fail_count -eq $FAILURE_THRESHOLD ]] && ! $lan_in_outage; then
            lan_outage_start=$(date "+%Y-%m-%d %H:%M:%S")
            log "OUTAGE_START" "LAN" "$LAN_TARGET" "" ""
            lan_in_outage=true
        fi
    fi

    wan1_ok=false
    wan2_ok=false
    ping_host "$WAN_TARGET_1" && wan1_ok=true
    ping_host "$WAN_TARGET_2" && wan2_ok=true

    if $wan1_ok || $wan2_ok; then
        if $wan_in_outage; then
            outage_end=$(date +%s)
            outage_start_epoch=$(date -d "$wan_outage_start" +%s)
            duration_min=$(( (outage_end - outage_start_epoch) / 60 ))
            [[ $duration_min -lt 1 ]] && duration_min=1
            log "OUTAGE_END" "WAN" "${WAN_TARGET_1}+${WAN_TARGET_2}" "$duration_min" "no"
            day_outage_count=$((day_outage_count + 1))
            day_total_downtime=$((day_total_downtime + duration_min))
            wan_in_outage=false
            wan_outage_start=""
        fi
        wan_fail_count=0
    else
        wan_fail_count=$((wan_fail_count + 1))
        if [[ $wan_fail_count -eq $FAILURE_THRESHOLD ]] && ! $wan_in_outage; then
            wan_outage_start=$(date "+%Y-%m-%d %H:%M:%S")
            log "OUTAGE_START" "WAN" "${WAN_TARGET_1}+${WAN_TARGET_2}" "" ""
            wan_in_outage=true
        fi
    fi

    sleep "$PING_INTERVAL"

done