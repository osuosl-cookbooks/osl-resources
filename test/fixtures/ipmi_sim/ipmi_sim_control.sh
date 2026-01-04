#!/bin/bash
# Script to manage ipmi_sim instances for kitchen testing
# Supports multiple instances on different ports for parallel VM testing
#
# Usage: ./ipmi_sim_control.sh <command> [instance_name]
#   Commands: start, stop, restart, status, start-all, stop-all
#   instance_name: Optional name for the instance (default: "default")
#                  Each instance gets unique ports based on its name
#
# Port allocation:
#   default:              LAN=9100, SYS=9101
#   osl-ipmi-user:        LAN=9110, SYS=9111
#   osl-ipmi-user-delete: LAN=9120, SYS=9121

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}"
EMU_FILE="${CONFIG_DIR}/kitchen-ipmi.emu"

# Get instance name (default to "default")
INSTANCE="${2:-default}"

# Calculate ports based on instance name
get_ports() {
    local instance="$1"
    case "$instance" in
        default)
            LAN_PORT=9100
            SYS_PORT=9101
            ;;
        osl-ipmi-user|osl_ipmi_user)
            LAN_PORT=9110
            SYS_PORT=9111
            ;;
        osl-ipmi-user-delete|osl_ipmi_user_delete)
            LAN_PORT=9120
            SYS_PORT=9121
            ;;
        osl-ipmi-user-modify|osl_ipmi_user_modify)
            LAN_PORT=9130
            SYS_PORT=9131
            ;;
        *)
            # Hash the instance name to get a port offset (0-9)
            local hash
            hash=$(echo -n "$instance" | md5sum | cut -c1-2)
            local offset=$((16#$hash % 10))
            LAN_PORT=$((9100 + offset * 10))
            SYS_PORT=$((LAN_PORT + 1))
            ;;
    esac
}

# Generate instance-specific config file
generate_config() {
    local instance="$1"
    local lan_port="$2"
    local sys_port="$3"
    local config_file="/tmp/kitchen-ipmi-${instance}.lan"

    cat > "$config_file" << EOF
# Auto-generated ipmi_sim config for instance: $instance
# LAN port: $lan_port, System interface port: $sys_port

name "kitchen-ipmi-$instance"

set_working_mc 0x20

  startlan 1
    addr 0.0.0.0 $lan_port
    priv_limit admin
    allowed_auths_callback none md2 md5 straight
    allowed_auths_user none md2 md5 straight
    allowed_auths_operator none md2 md5 straight
    allowed_auths_admin none md2 md5 straight
    guid a123456789abcdefa123456789abcdef
  endlan

  serial 15 0.0.0.0 $sys_port codec VM

  user 1 true  ""           ""       user     10  none md2 md5 straight
  user 2 true  "admin"      "admin"  admin    10  none md2 md5 straight
EOF

    echo "$config_file"
}

get_ports "$INSTANCE"
STATE_DIR="/tmp/kitchen-ipmi-state-${INSTANCE}"
PID_FILE="/tmp/kitchen-ipmi-${INSTANCE}.pid"
LOG_FILE="/tmp/kitchen-ipmi-${INSTANCE}.log"

start() {
    LAN_CONF=$(generate_config "$INSTANCE" "$LAN_PORT" "$SYS_PORT")

    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo "ipmi_sim ($INSTANCE) is already running (PID: $(cat "$PID_FILE"))"
        echo "Ports: LAN=$LAN_PORT, SYS=$SYS_PORT"
        return 0
    fi

    mkdir -p "$STATE_DIR"

    echo "Starting ipmi_sim instance: $INSTANCE"
    echo "Config: $LAN_CONF"
    echo "Ports: LAN=$LAN_PORT, SYS=$SYS_PORT"

    ipmi_sim -c "$LAN_CONF" -f "$EMU_FILE" -s "$STATE_DIR" -n -d > "$LOG_FILE" 2>&1 &
    PID=$!
    echo $PID > "$PID_FILE"

    sleep 1
    if kill -0 "$PID" 2>/dev/null; then
        echo "ipmi_sim ($INSTANCE) started (PID: $PID)"
        echo "System interface (for QEMU): 0.0.0.0:$SYS_PORT"
        echo "Log file: $LOG_FILE"
        return 0
    else
        echo "ERROR: ipmi_sim ($INSTANCE) failed to start. Check $LOG_FILE"
        cat "$LOG_FILE"
        rm -f "$PID_FILE"
        return 1
    fi
}

stop() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if kill -0 "$PID" 2>/dev/null; then
            echo "Stopping ipmi_sim ($INSTANCE) (PID: $PID)..."
            kill "$PID"
            rm -f "$PID_FILE"
            echo "ipmi_sim ($INSTANCE) stopped"
        else
            echo "ipmi_sim ($INSTANCE) is not running (stale PID file)"
            rm -f "$PID_FILE"
        fi
    else
        echo "ipmi_sim ($INSTANCE) is not running (no PID file)"
    fi
}

reset() {
    # Stop the instance and clear all state (for fresh converge testing)
    stop
    if [ -d "$STATE_DIR" ]; then
        echo "Clearing ipmi_sim state directory: $STATE_DIR"
        rm -rf "$STATE_DIR"
    fi
    sleep 1
    start
}

stop_all() {
    echo "Stopping all ipmi_sim instances..."
    for pidfile in /tmp/kitchen-ipmi-*.pid; do
        if [ -f "$pidfile" ]; then
            instance=$(basename "$pidfile" .pid | sed 's/kitchen-ipmi-//')
            PID=$(cat "$pidfile")
            if kill -0 "$PID" 2>/dev/null; then
                echo "Stopping ipmi_sim ($instance) (PID: $PID)..."
                kill "$PID"
            fi
            rm -f "$pidfile"
        fi
    done
    pkill -f "ipmi_sim.*kitchen-ipmi" 2>/dev/null || true
    echo "All instances stopped"
}

start_all() {
    echo "Starting ipmi_sim instances for all known suites..."
    for suite in osl-ipmi-user osl-ipmi-user-delete; do
        INSTANCE="$suite"
        get_ports "$INSTANCE"
        STATE_DIR="/tmp/kitchen-ipmi-state-${INSTANCE}"
        PID_FILE="/tmp/kitchen-ipmi-${INSTANCE}.pid"
        LOG_FILE="/tmp/kitchen-ipmi-${INSTANCE}.log"
        start
        echo ""
    done
}

status() {
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo "ipmi_sim ($INSTANCE) is running (PID: $(cat "$PID_FILE"))"
        echo "Ports: LAN=$LAN_PORT, SYS=$SYS_PORT"
        return 0
    else
        echo "ipmi_sim ($INSTANCE) is not running"
        return 1
    fi
}

status_all() {
    echo "Status of all ipmi_sim instances:"
    for pidfile in /tmp/kitchen-ipmi-*.pid; do
        if [ -f "$pidfile" ]; then
            instance=$(basename "$pidfile" .pid | sed 's/kitchen-ipmi-//')
            INSTANCE="$instance"
            get_ports "$INSTANCE"
            PID_FILE="$pidfile"
            status
            echo ""
        fi
    done
    echo "Listening IPMI ports:"
    ss -tlnp 2>/dev/null | grep -E '91[0-9][0-9]' || echo "  (none)"
}

get_port() {
    echo "$SYS_PORT"
}

case "${1:-}" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        stop
        sleep 1
        start
        ;;
    reset)
        reset
        ;;
    status)
        status
        ;;
    start-all)
        start_all
        ;;
    stop-all)
        stop_all
        ;;
    status-all)
        status_all
        ;;
    get-port)
        get_port
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|reset|status|start-all|stop-all|status-all|get-port} [instance_name]"
        echo ""
        echo "Examples:"
        echo "  $0 start                    # Start default instance on ports 9100/9101"
        echo "  $0 start osl-ipmi-user      # Start instance on 9110/9111"
        echo "  $0 reset osl-ipmi-user      # Reset state and restart (for fresh converge)"
        echo "  $0 start-all                # Start instances for all known suites"
        echo "  $0 stop-all                 # Stop all running instances"
        echo "  $0 get-port osl-ipmi-user   # Get system interface port (9111)"
        exit 1
        ;;
esac
