#!/bin/bash

# Set window title
echo -ne "\033]0;OpenVPN Monitor V1.1 | By Bassings\007"

STATUS_LOG="/etc/openvpn/server/status.log"
TEMP_USER_LIST="/tmp/current_users.txt"
PREVIOUS_USER_LIST="/tmp/previous_users.txt"
USER_CONNECTION_COUNTS="/tmp/user_connection_counts.txt"
USER_MESSAGE_IDS="/tmp/user_message_ids.txt"
USER_CONNECTION_TIMES="/tmp/user_connection_times.txt"

SERVER_LOCATION="London, United Kingdom"

touch "$TEMP_USER_LIST" "$PREVIOUS_USER_LIST" "$USER_CONNECTION_COUNTS" "$USER_MESSAGE_IDS" "$USER_CONNECTION_TIMES"

WEBHOOK_FILE="/root/webhook.txt"
UPTIME_MONITOR_FILE="/root/uptimemonitorlink.txt"

# Check for required files
if [[ -f "$WEBHOOK_FILE" ]]; then
    WEBHOOK_URL=$(cat "$WEBHOOK_FILE")
    echo -e "\033[32mSuccessfully\033[0m found $WEBHOOK_FILE"
else
    echo -e "\033[31mFailed\033[0m to find $WEBHOOK_FILE"
fi

if [[ -f "$UPTIME_MONITOR_FILE" ]]; then
    UPTIME_MONITOR_LINK=$(cat "$UPTIME_MONITOR_FILE")
    echo -e "\033[32mSuccessfully\033[0m found $UPTIME_MONITOR_FILE"
else
    echo -e "\033[31mFailed\033[0m to find $UPTIME_MONITOR_FILE"
fi

get_server_uptime() {
    uptime -p | sed 's/up //'
}

send_webhook() {
    local username="$1"
    local client_ip="$2"
    local total_connections="$3"
    local event="$4"
    local connection_duration="$5"

    local server_uptime=$(get_server_uptime)
    local spoiler_client_ip="||$client_ip||"

    local embed_color
    if [[ "$event" == "Connected" ]]; then
        embed_color=3066993  # Green
    else
        embed_color=15158332  # Red
    fi

    local message="{
        \"embeds\": [ {
            \"color\": $embed_color,
            \"title\": \"**OpenVPN Connection Event**\",
            \"description\": \"User has $event.\",
            \"fields\": [
                {\"name\": \"Username\", \"value\": \"$username\", \"inline\": true},
                {\"name\": \"Real IP\", \"value\": \"$spoiler_client_ip\", \"inline\": true},
                {\"name\": \"Uptime Monitor\", \"value\": \"[Click Here]($UPTIME_MONITOR_LINK)\", \"inline\": true},
                {\"name\": \"Total Connections\", \"value\": \"$total_connections\", \"inline\": true},
                {\"name\": \"Server Location\", \"value\": \"$SERVER_LOCATION\", \"inline\": true},
                {\"name\": \"Server Uptime\", \"value\": \"$server_uptime\", \"inline\": true} "
    if [[ "$event" == "Disconnected" && -n "$connection_duration" ]]; then
        message+=",{\"name\": \"Connection Duration\", \"value\": \"$connection_duration\", \"inline\": true} "
    fi
    message+="],
            \"image\": {
                \"url\": \"https://i.imgur.com/m2cvsRt.gif\"
            },
            \"footer\": {\"text\": \"OpenVPN Server Notification\"},
            \"timestamp\": \"$(date --utc +%FT%TZ)\"
        } ]
    }"

    response=$(curl -s -w "%{http_code}" -o /dev/null -X POST -H "Content-Type: application/json" -d "$message" "$WEBHOOK_URL")

    if [[ "$response" -eq 204 ]]; then
        echo "Webhook sent successfully."
    else
        echo "Error sending webhook. HTTP Response code: $response"
    fi
}

get_cpu_load() {
    awk '{print $1}' /proc/loadavg
}

get_available_disk_space() {
    df -h / | awk 'NR==2 {print $4}'
}

get_memory_usage() {
    free -h | awk 'NR==2 {print $3 "/" $2}'
}

echo -e "\033[32mSuccessfully\033[0m hooked to /etc/openvpn/server/status.log"
echo -e "Server Statistics:"
echo -e "- CPU Load: $(get_cpu_load)"
echo -e "- Available Disk Space: $(get_available_disk_space)"
echo -e "- Memory Usage: $(get_memory_usage)"

get_current_users() {
    grep "^CLIENT_LIST" "$STATUS_LOG" | while IFS=',' read -ra fields; do
        username="${fields[1]}"
        client_ip="${fields[2]}"
        echo "$username $client_ip"
    done
}

increment_connection_count() {
    local username="$1"
    local count

    count=$(grep "^$username " "$USER_CONNECTION_COUNTS" | awk '{print $2}')
    if [[ -z "$count" ]]; then
        count=0
    fi

    count=$((count + 1))
    sed -i "/^$username /d" "$USER_CONNECTION_COUNTS"
    echo "$username $count" >> "$USER_CONNECTION_COUNTS"

    echo "$count"
}

record_connection_time() {
    local username="$1"
    local start_time=$(date +%s)
    sed -i "/^$username /d" "$USER_CONNECTION_TIMES"
    echo "$username $start_time" >> "$USER_CONNECTION_TIMES"
}

get_connection_duration() {
    local username="$1"
    local start_time

    start_time=$(grep "^$username " "$USER_CONNECTION_TIMES" | awk '{print $2}' | head -n 1)

    if [[ -n "$start_time" ]]; then
        local current_time=$(date +%s)
        local duration=$((current_time - start_time))

        local hours=$((duration / 3600))
        local minutes=$(((duration % 3600) / 60))
        local seconds=$((duration % 60))

        printf "%02d:%02d:%02d" $hours $minutes $seconds
    else
        echo "00:00:00"  # Default value if no start time found
    fi
}

detect_changes() {
    # Get the current user list
    get_current_users > "$TEMP_USER_LIST"

    if [[ -f "$PREVIOUS_USER_LIST" ]]; then
        # Handle new connections
        comm -13 <(sort "$PREVIOUS_USER_LIST") <(sort "$TEMP_USER_LIST") | while read -r line; do
            username=$(echo "$line" | awk '{print $1}')
            client_ip=$(echo "$line" | awk '{print $2}')
            total_connections=$(increment_connection_count "$username")
            record_connection_time "$username"
            echo -e "\033[32mUser Connected: $username (IP: $client_ip, Total Connections: $total_connections)\033[0m"
            send_webhook "$username" "$client_ip" "$total_connections" "Connected"
        done

        # Handle disconnections
        comm -23 <(sort "$PREVIOUS_USER_LIST") <(sort "$TEMP_USER_LIST") | while read -r line; do
            username=$(echo "$line" | awk '{print $1}')
            client_ip=$(echo "$line" | awk '{print $2}')
            total_connections=$(grep "^$username " "$USER_CONNECTION_COUNTS" | awk '{print $2}')
            connection_duration=$(get_connection_duration "$username")
            echo -e "\033[31mUser Disconnected: $username (IP: $client_ip, Total Connections: $total_connections, Connection Duration: $connection_duration)\033[0m"
            send_webhook "$username" "$client_ip" "$total_connections" "Disconnected" "$connection_duration"
        done
    fi

    if [[ -f "$TEMP_USER_LIST" ]]; then
        mv "$TEMP_USER_LIST" "$PREVIOUS_USER_LIST"
    fi
}

inotifywait -m -e modify "$STATUS_LOG" | while read -r path action file; do
    detect_changes
done
