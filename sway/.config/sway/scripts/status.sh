#!/bin/sh

### --- Configuration ---
THEME_FILE="$HOME/.config/sway/themes/sway_current.conf"

get_color() {
  target_var=$1
  [ "$target_var" = "dim" ] && target_var="subtle"
  [ "$target_var" = "vpn" ] && target_var="pine"

  color=$(grep -i "set \$$target_var" "$THEME_FILE" 2>/dev/null | awk '{print $3}' | head -n 1)

  if [ -z "$color" ]; then
    case "$1" in
    "text") echo "#e0def4" ;;
    "love") echo "#eb6f92" ;;
    "gold") echo "#f6c177" ;;
    "subtle") echo "#908caa" ;;
    "pine") echo "#31748f" ;;
    *) echo "#ffffff" ;;
    esac
  else
    echo "$color"
  fi
}

### --- System Modules ---

get_cpu() {
  # LC_ALL=C forces standard English formatting.
  # -n2 runs top twice. The first is since boot, the second is real-time.
  # -d 0.2 waits 0.2 seconds between the two checks to calculate the difference.
  # tail -n 1 grabs only the output from that second, real-time check.
  val=$(LC_ALL=C top -bn2 -d 0.2 | grep "Cpu(s)" | tail -n 1 | awk '{print 100 - $8}')

  clr=$COLOR_TEXT
  [ "$(echo "$val > 80" | bc)" -eq 1 ] && clr=$COLOR_ALERT

  printf " <span foreground='%s'>%0.1f%%</span>" "$clr" "$val"
}

get_temp() {
  temp=0

  # Search through thermal zones for the actual CPU (Intel, AMD, or ARM)
  for t in /sys/class/thermal/thermal_zone*/type; do
    type_name=$(cat "$t" 2>/dev/null)
    if [ "$type_name" = "x86_pkg_temp" ] || [ "$type_name" = "coretemp" ] || [ "$type_name" = "k10temp" ] || [ "$type_name" = "cpu_thermal" ]; then
      # If matched, read the 'temp' file in that exact same directory
      temp=$(cat "${t%type}temp" 2>/dev/null)
      break
    fi
  done

  # Fallback just in case the CPU zone wasn't found
  if [ -z "$temp" ] || [ "$temp" -eq 0 ]; then
    temp=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo 0)
  fi

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
  # Let awk do all the grabbing and math in one single extremely fast process
  read used total perc gib <<< $(free -m | awk '/Mem:/ {
      printf "%d %d %d %.1f\n", $3, $2, (100*$3/$2), ($3/1024)
  }')
  
  clr=$COLOR_TEXT
  if [ "$perc" -gt 80 ]; then 
    clr=$COLOR_ALERT
  elif [ "$perc" -gt 65 ]; then 
    clr=$COLOR_WARN
  fi
  
  echo " <span foreground='$clr'>${gib}GiB</span>"
}

get_net() {
  # 1. Detect VPN
  vpn_active=$(nmcli -t -f TYPE,STATE dev | grep -E "^(vpn|wireguard):connected" | head -n 1)

  # 2. Set colors based on VPN status
  if [ -n "$vpn_active" ]; then
    main_clr="$COLOR_VPN"
    label=" (VPN)"
  else
    main_clr="$COLOR_TEXT"
    label=""
  fi

  # 3. Ethernet Logic
  eth_iface=$(ls /sys/class/net | grep '^e' | head -n 1)
  if [ -n "$eth_iface" ] && grep -q "1" "/sys/class/net/$eth_iface/carrier" 2>/dev/null; then
    echo "<span foreground='$main_clr'>󰈀 $eth_iface$label</span>"
    return
  fi

  # 4. WiFi Logic
  net_data=$(nmcli -t -f active,device,signal dev wifi | grep '^yes' | head -n 1)
  if [ -n "$net_data" ]; then
    iface=$(echo "$net_data" | cut -d: -f2)
    signal=$(echo "$net_data" | cut -d: -f3)
    rssi=$(((signal / 2) - 100))

    # Pick icon
    [ "$signal" -ge 80 ] && icon="󰤨" || { [ "$signal" -ge 60 ] && icon="󰤥" || icon="󰤟"; }

    echo "<span foreground='$main_clr'>$icon $iface$label</span> <span foreground='$COLOR_DIM'>(${rssi}dBm)</span>"
  else
    echo "<span foreground='$COLOR_ALERT'>󰖪 Offline</span>"
  fi
}

get_vol() {
  # Check if muted
  mute=$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | grep -o 'yes')
  if [ "$mute" = "yes" ]; then
    echo "<span foreground='$COLOR_DIM'>󰖁 Muted</span>"
    return
  fi

  # Extract the volume percentage number
  vol=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -o '[0-9]*%' | head -n1 | tr -d '%')

  # Fallback if audio server isn't responding
  if [ -z "$vol" ]; then
    echo "<span foreground='$COLOR_DIM'>󰝟 ---</span>"
    return
  fi

  # Change color to yellow/gold if volume is pushed past 100% (over-amplified)
  clr=$COLOR_TEXT
  if [ "$vol" -gt 100 ]; then clr=$COLOR_WARN; fi

  # Change icon based on volume level
  [ "$vol" -ge 65 ] && icon="󰕾" || { [ "$vol" -ge 30 ] && icon="󰖀" || icon="󰕿"; }

  echo "<span foreground='$clr'>$icon ${vol}%</span>"
}

get_mic() {
  # 1. Try to get mute status. We hide errors (2>/dev/null) to gracefully handle missing mics.
  mute_output=$(pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null)

  # 2. Handle "No Mic Found"
  # If the command returned absolutely nothing, the audio server has no default source.
  if [ -z "$mute_output" ]; then
    echo "<span foreground='$COLOR_DIM'>󰍭 None</span>"
    return
  fi

  # 3. Handle Muted State
  if echo "$mute_output" | grep -q 'yes'; then
    echo "<span foreground='$COLOR_DIM'>󰍭 Muted</span>"
    return
  fi

  # 4. Extract Volume
  vol=$(pactl get-source-volume @DEFAULT_SOURCE@ 2>/dev/null | grep -o '[0-9]*%' | head -n1 | tr -d '%')

  # Fallback if extraction fails
  if [ -z "$vol" ]; then
    echo "<span foreground='$COLOR_DIM'>󰍭 ---</span>"
    return
  fi

  # Change color to yellow/gold if mic is peaking/over-amplified (above 100%)
  clr=$COLOR_TEXT
  if [ "$vol" -gt 100 ]; then clr=$COLOR_WARN; fi

  echo "<span foreground='$clr'>󰍬 ${vol}%</span>"
}

get_music() {
  # Select target player: prefer mpd, fallback to any active player
  if playerctl -l 2>/dev/null | grep -q "mpd"; then
    target="mpd"
  else
    target="%any"
  fi

  # Get player status
  status=$(playerctl --player="$target" status 2>/dev/null)
  if [ "$status" != "Playing" ] && [ "$status" != "Paused" ]; then
    return
  fi

  # Fetch metadata using template
  info=$(playerctl --player="$target" metadata --format "{{ artist }} - {{ title }}" 2>/dev/null)

  # Fallback for missing tags or streams
  if [ "$info" = " - " ] || [ -z "$info" ]; then
    info=$(playerctl --player="$target" metadata --format "{{ xesam:title }}" 2>/dev/null)
  fi
  [ -z "$info" ] && info="Unknown Source"

  # Truncate string for bar stability
  if [ ${#info} -gt 35 ]; then
    display="$(echo "$info" | cut -c 1-32)..."
  else
    display="$info"
  fi

  # State-based icons
  [ "$status" = "Playing" ] && icon="󰎈" || icon="󰏤"

  echo "<span foreground='$COLOR_DIM'>$icon </span><span foreground='$COLOR_TEXT'>$display</span>"
}

### --- Main Execution ---
while true; do
  COLOR_TEXT=$(get_color "text")
  COLOR_ALERT=$(get_color "love")
  COLOR_WARN=$(get_color "gold")
  COLOR_DIM=$(get_color "subtle")
  COLOR_VPN=$(get_color "vpn")

  NET_MOD=$(get_net)
  MUSIC_MOD=$(get_music)
  VOL_MOD=$(get_vol)
  MIC_MOD=$(get_mic)
  CPU_MOD=$(get_cpu)
  TMP_MOD=$(get_temp)
  RAM_MOD=$(get_ram)
  TIME_MOD=$(date +'%d-%m-%Y %H:%M:%S')

  [ -n "$MUSIC_MOD" ] && MUSIC_OUT="$MUSIC_MOD | " || MUSIC_OUT=""

  echo "$MUSIC_OUT$NET_MOD | $VOL_MOD  $MIC_MOD | $CPU_MOD $TMP_MOD | $RAM_MOD |  $TIME_MOD "
  sleep 1
done
