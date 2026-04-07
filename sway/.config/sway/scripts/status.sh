#!/bin/sh

### --- Configuration & Theme ---
# Point this to the symlink that the switcher script manages
THEME_FILE="$HOME/.config/sway/theme_current.conf"

# Extract hex colors with a fallback if the file or variable is missing
get_color() {
  # 1. Try to get the color from the theme file
  # 2. If empty or file missing, return a hardcoded fallback (Rosé Pine Dark defaults)
  color=$(grep -i "set \$$1" "$THEME_FILE" 2>/dev/null | awk '{print $3}' | head -n 1)

  if [ -z "$color" ]; then
    case "$1" in
    "text") echo "#e0def4" ;;
    "love") echo "#eb6f92" ;;
    "gold") echo "#f6c177" ;;
    "muted") echo "#6e6a86" ;;
    *) echo "#ffffff" ;;
    esac
  else
    echo "$color"
  fi
}

# Source the colors
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
  # Check for Ethernet (e*)
  eth_iface=$(ls /sys/class/net | grep '^e' | head -n 1)
  if [ -n "$eth_iface" ] && grep -q "1" "/sys/class/net/$eth_iface/carrier" 2>/dev/null; then
    echo "󰈀 $eth_iface"
    return
  fi

  # Extract Interface and Signal Strength for active Wi-Fi
  # nmcli -t -f active,device,signal dev wifi returns: yes:wlan0:85
  net_data=$(nmcli -t -f active,device,signal dev wifi | grep '^yes' | head -n 1)

  if [ -n "$net_data" ]; then
    iface=$(echo "$net_data" | cut -d: -f2)
    signal=$(echo "$net_data" | cut -d: -f3)

    # Convert 0-100 signal to dBm approximation
    rssi=$(((signal / 2) - 100))

    # Icon mapping
    if [ "$signal" -ge 80 ]; then
      icon="󰤨"
    elif [ "$signal" -ge 60 ]; then
      icon="󰤥"
    elif [ "$signal" -ge 40 ]; then
      icon="󰤢"
    elif [ "$signal" -ge 20 ]; then
      icon="󰤟"
    else
      icon="󰤭"
    fi

    echo "$icon $iface <span foreground='$COLOR_DIM'>(${rssi}dBm)</span>"
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
