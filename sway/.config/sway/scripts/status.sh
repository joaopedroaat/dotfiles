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

# Returns formatted CPU string with icon and color logic
get_cpu() {
  val=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')
  clr=$COLOR_TEXT

  if [ "$(echo "$val > 80" | bc)" -eq 1 ]; then
    clr=$COLOR_ALERT
  fi

  printf " <span foreground='%s'>%0.1f%%</span>" "$clr" "$val"
}

# Returns formatted Temperature string with color logic
get_temp() {
  temp=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo 0)
  temp=$((temp / 1000))
  clr=$COLOR_DIM

  if [ "$temp" -gt 80 ]; then
    clr=$COLOR_ALERT
  elif [ "$temp" -gt 65 ]; then
    clr=$COLOR_WARN
  fi

  echo "<span foreground='$clr'>( ${temp}°C)</span>"
}

# Returns formatted RAM string with icon and usage-based color logic
get_ram() {
  # Extract used and total memory in MB
  mem_data=$(free -m | awk '/Mem:/ {print $3, $2}')
  used=$(echo "$mem_data" | awk '{print $1}')
  total=$(echo "$mem_data" | awk '{print $2}')

  # Calculate percentage and GiB usage
  perc=$((100 * used / total))
  gib=$(echo "scale=1; $used/1024" | bc)

  clr=$COLOR_TEXT
  if [ "$perc" -gt 80 ]; then
    clr=$COLOR_ALERT
  elif [ "$perc" -gt 65 ]; then
    clr=$COLOR_WARN
  fi

  echo " <span foreground='$clr'>${gib}GiB</span>"
}

# Returns formatted Network string with WiFi signal strength logic
get_net() {
  if grep -q "1" /sys/class/net/e*/carrier 2>/dev/null; then
    echo "󰈀 Wired"
    return
  fi

  interface=$(ls /sys/class/net | grep '^w' | head -n 1)
  ssid=$(iwctl station list | grep "connected" | awk '{print $2}')

  if [ -n "$ssid" ] && [ -n "$interface" ]; then
    rssi=$(iwctl station "$interface" show | grep "AverageRSSI" | awk '{print $2}')
    [ -z "$rssi" ] && rssi=$(iwctl station "$interface" show | grep "RSSI" | awk '{print $2}')

    if [ "$rssi" -ge -50 ]; then
      icon="󰤨"
    elif [ "$rssi" -ge -60 ]; then
      icon="󰤥"
    elif [ "$rssi" -ge -70 ]; then
      icon="󰤢"
    elif [ "$rssi" -ge -80 ]; then
      icon="󰤟"
    else icon="󰤭"; fi

    echo "$icon $ssid <span foreground='$COLOR_DIM'>(${rssi}dBm)</span>"
  else
    echo "<span foreground='$COLOR_ALERT'>󰖪 Offline</span>"
  fi
}

### --- Main Loop ---
while true; do
  # Modular Data Acquisition
  NET_MOD=$(get_net)
  CPU_MOD=$(get_cpu)
  TMP_MOD=$(get_temp)
  RAM_MOD=$(get_ram)
  TIME_MOD=$(date +'%d-%m-%Y %H:%M:%S')

  # Status Bar Output
  echo "$NET_MOD | $CPU_MOD $TMP_MOD | $RAM_MOD |  $TIME_MOD "

  sleep 1
done
