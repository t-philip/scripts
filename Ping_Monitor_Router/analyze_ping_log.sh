#!/usr/bin/env bash
# =============================================================================
# analyze_ping_log.sh — Ping Monitor Log Analyser
# Platform : Ubuntu 24.04 LTS (container or VM on any Linux host)
# Author   : t-philip / Claude
# Version  : 1.0
# =============================================================================

LOG_FILE="${1:-/var/log/ping_monitor/ping_monitor.log}"

if [[ ! -f "$LOG_FILE" ]]; then
    echo "ERROR: Log file not found: $LOG_FILE"
    exit 1
fi

total_outages=0
lan_restarts=0
wan_outages=0
total_downtime=0
longest_duration=0
longest_event=""
monitor_start=""
monitor_end=""

declare -a outage_lines=()

while IFS=',' read -r ts event ttype tip duration probable_restart; do
    [[ "$ts" == "timestamp" ]] && continue

    case "$event" in
        MONITOR_START)
            [[ -z "$monitor_start" ]] && monitor_start="$ts"
            ;;
        OUTAGE_END)
            total_outages=$((total_outages + 1))
            dur="${duration:-0}"
            total_downtime=$((total_downtime + dur))

            if [[ "$ttype" == "LAN" ]]; then
                lan_restarts=$((lan_restarts + 1))
                restart_flag="← probable restart"
            else
                wan_outages=$((wan_outages + 1))
                restart_flag=""
            fi

            if [[ $dur -gt $longest_duration ]]; then
                longest_duration=$dur
                longest_event="$ts | $ttype | ${dur} min $restart_flag"
            fi

            outage_lines+=("  #${total_outages}  ${ts}  ${ttype}  Duration: ${dur} min  ${restart_flag}")
            monitor_end="$ts"
            ;;
        DAILY_SUMMARY)
            monitor_end="$ts"
            ;;
    esac
done < "$LOG_FILE"

echo ""
echo "============================================================"
echo "  Ping Monitor Report"
echo "  Log file : $LOG_FILE"
[[ -n "$monitor_start" ]] && echo "  From     : $monitor_start"
[[ -n "$monitor_end"   ]] && echo "  To       : $monitor_end"
echo "============================================================"
echo ""
echo "  Total outages detected    : $total_outages"
echo "  Probable restarts (LAN)   : $lan_restarts"
echo "  WAN-only outages          : $wan_outages"
echo "  Total downtime            : ${total_downtime} min"
echo ""
if [[ $total_outages -gt 0 ]]; then
    echo "  Longest outage            : $longest_event"
    echo ""
    echo "  Outage detail:"
    for line in "${outage_lines[@]}"; do
        echo "$line"
    done
else
    echo "  No outages recorded in this log."
fi
echo ""
echo "============================================================"
echo ""