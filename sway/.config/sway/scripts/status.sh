#!/bin/sh

### --- Configuration & Theme ---
CONFIG_PATH="$HOME/.config/sway/config.d/01_theme.conf"

# Extract hex colors from Sway configuration
get_color() {
    grep -i "set \$$1" "$CONFIG_PATH" | awk '{print $3}' | head -n 1
}

COLOR_TEXT=$(get_color "text")
COLOR_ALERT=$(get_color "love")
COLOR_WARN=$(get_color "gold")
COLOR_DIM=$(get_color "muted")

### --- System Functions ---

# Get CPU load percentage
get_cpu() {
    top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8"%"}'
}

# Get CPU temperature in Celsius
get_temp() {
    temp=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo 0)
    echo $((temp / 1000))
}

# Get used RAM in GiB
get_ram() {
    free -m | awk '/Mem:/ { printf "%0.1fGiB", $3/1024 }'
}

# Get Network status via Ethernet carrier or iwctl station list
get_net() {
    # Check for Ethernet connection
    if grep -q "1" /sys/class/net/e*/carrier 2>/dev/null; then
        echo "󰈀 Wired"
        return
    fi

    # Check for WiFi connection via iwd
    ssid=$(iwctl station list | grep "connected" | awk '{print $2}')
    
    if [ -n "$ssid" ]; then
        echo "󰖩 $ssid"
    else
        echo "<span foreground='$COLOR_ALERT'>󰖪 Offline</span>"
    fi
}

### --- Main Loop ---
while true; do
    # Fetch Data
    CPU=$(get_cpu)
    TEMP=$(get_temp)
    RAM=$(get_ram)
    NET=$(get_net)
    TIME=$(date +'%d-%m-%Y %H:%M:%S')

    # CPU Color Logic
    CPU_VAL=$(echo "$CPU" | tr -d '%')
    CPU_CLR=$COLOR_TEXT
    [ "$(echo "$CPU_VAL > 80" | bc)" -eq 1 ] && CPU_CLR=$COLOR_ALERT
    
    # Temperature Color Logic
    TEMP_CLR=$COLOR_TEXT
    if [ "$TEMP" -gt 80 ]; then TEMP_CLR=$COLOR_ALERT;
    elif [ "$TEMP" -gt 65 ]; then TEMP_CLR=$COLOR_WARN; fi

    # Status Bar Output (Pango Markup)
    echo "$NET |  <span foreground='$CPU_CLR'>$CPU</span> <span foreground='$COLOR_DIM'>( ${TEMP}°C)</span> |  $RAM |  $TIME "
    
    sleep 1
done
