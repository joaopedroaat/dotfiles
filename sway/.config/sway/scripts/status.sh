#!/bin/sh

get_cpu() {
    top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}'
}

get_temp() {
    temp=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo 0)
    echo $((temp / 1000))
}

get_ram() {
    free -m | awk '/Mem:/ { printf "%0.1f", $3/1024 }'
}

while true; do
    # CPU Logic & Icon ()
    CPU=$(get_cpu)
    CPU_COLOR="#ffffff"
    if [ "$(echo "$CPU > 80" | bc)" -eq 1 ]; then CPU_COLOR="#ff0000"; fi

    # Temp Logic & Icon ()
    TEMP=$(get_temp)
    TEMP_COLOR="#ffffff"
    if [ "$TEMP" -gt 80 ]; then TEMP_COLOR="#ff0000";
    elif [ "$TEMP" -gt 65 ]; then TEMP_COLOR="#ffaa00"; fi

    # RAM Logic & Icon ()
    RAM=$(get_ram)
    RAM_COLOR="#ffffff"
    if [ "$(echo "$RAM > 12" | bc)" -eq 1 ]; then RAM_COLOR="#ffff00"; fi

    # Time Icon ()
    TIME=$(date +'%d-%m-%Y %H:%M:%S')

    # Output with Nerd Font Icons and Pango Colors
    echo "  <span foreground='$CPU_COLOR'>${CPU}%</span> ( <span foreground='$TEMP_COLOR'>${TEMP}°C</span>) |   <span foreground='$RAM_COLOR'>${RAM}GiB</span> |   $TIME"
    
    sleep 1
done
