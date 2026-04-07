#!/bin/sh

### --- Configuration ---
THEME_FILE="$HOME/.config/sway/themes/theme_current.conf"

# Fetch hex codes from theme configuration
get_color() {
  target_var=$1
  # Map 'dim' to 'subtle' for better legibility across themes
  [ "$target_var" = "dim" ] && target_var="subtle"

  color=$(grep -i "set \$$target_var" "$THEME_FILE" 2>/dev/null | awk '{print $3}' | head -n 1)

  if [ -z "$color" ]; then
    case "$1" in
    "text") echo "#e0def4" ;;
    "love") echo "#eb6f92" ;;
    "gold") echo "#f6c177" ;;
    "subtle") echo "#908caa" ;;
    *) echo "#ffffff" ;;
    esac
  else
    echo "$color"
  fi
}

### --- System Modules ---

get_cpu() {
  val=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')
  clr=$COLOR_TEXT
  [ "$(echo "$val > 80" | bc)" -eq 1 ] && clr=$COLOR_ALERT
  printf " <span foreground='%s'>%0.1f%%</span>" "$clr" "$val"
}

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

get_ram() {
  mem_data=$(free -m | awk '/Mem:/ {print $3, $2}')
  used=$(echo "$mem_data" | awk '{print $1}')
  total=$(echo "$mem_data" | awk '{print $2}')
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

get_net() {
  eth_iface=$(ls /sys/class/net | grep '^e' | head -n 1)
  if [ -n "$eth_iface" ] && grep -q "1" "/sys/class/net/$eth_iface/carrier" 2>/dev/null; then
    echo "󰈀 $eth_iface"
    return
  fi

  net_data=$(nmcli -t -f active,device,signal dev wifi | grep '^yes' | head -n 1)
  if [ -n "$net_data" ]; then
    iface=$(echo "$net_data" | cut -d: -f2)
    signal=$(echo "$net_data" | cut -d: -f3)
    rssi=$(((signal / 2) - 100))
    [ "$signal" -ge 80 ] && icon="󰤨" || { [ "$signal" -ge 60 ] && icon="󰤥" || icon="󰤟"; }
    echo "$icon $iface <span foreground='$COLOR_DIM'>(${rssi}dBm)</span>"
  else
    echo "<span foreground='$COLOR_ALERT'>󰖪 Offline</span>"
  fi
}

### --- Main Execution ---
while true; do
  # Update theme variables
  COLOR_TEXT=$(get_color "text")
  COLOR_ALERT=$(get_color "love")
  COLOR_WARN=$(get_color "gold")
  COLOR_DIM=$(get_color "subtle")

  # Data Acquisition
  NET_MOD=$(get_net)
  CPU_MOD=$(get_cpu)
  TMP_MOD=$(get_temp)
  RAM_MOD=$(get_ram)
  TIME_MOD=$(date +'%d-%m-%Y %H:%M:%S')

  # Output
  echo "$NET_MOD | $CPU_MOD $TMP_MOD | $RAM_MOD |  $TIME_MOD "

  sleep 1
done
