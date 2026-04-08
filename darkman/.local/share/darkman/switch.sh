#!/bin/sh
# Unified Theme & Environment Switcher
# Controlled by Darkman

# --- Environment ---
# Ensure environment is available before running Wayland commands
export $(systemctl --user show-environment | grep -E '^WAYLAND_DISPLAY|^SWAYSOCK')

# --- Configuration ---
THEME_DIR="$HOME/.config/sway/themes"
MAKO_LINK="$HOME/.config/mako/theme_current"

# Temperature Settings
NIGHT_TMP=3500
DAY_TMP=6000

case "$1" in
dark)
  # 1. System Appearance
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

  # 2. Config Symlinks
  ln -sf "$THEME_DIR/sway_dark.conf" "$THEME_DIR/sway_current.conf"
  ln -sf "$THEME_DIR/mako_dark.conf" "$MAKO_LINK"

  # 3. Night Light (wlsunset)
  pkill wlsunset && sleep 0.1
  # FIX: Set high temp to +1 of low temp to bypass the check
  wlsunset -T $((NIGHT_TMP + 1)) -t $NIGHT_TMP >/dev/null 2>&1 &

  TITLE="󰖔  evening"
  MSG="dark theme • $NIGHT_TMP K"
  ;;

light)
  # 1. System Appearance
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'

  # 2. Config Symlinks
  ln -sf "$THEME_DIR/sway_light.conf" "$THEME_DIR/sway_current.conf"
  ln -sf "$THEME_DIR/mako_light.conf" "$MAKO_LINK"

  # 3. Night Light (wlsunset)
  pkill wlsunset && sleep 0.1
  # FIX: Set high temp to +1 of low temp to bypass the check
  wlsunset -T $((DAY_TMP + 1)) -t $DAY_TMP >/dev/null 2>&1 &

  TITLE="󰖙  daylight"
  MSG="light theme • $DAY_TMP K"
  ;;
esac

# --- Apply Changes Live ---
makoctl reload
swaymsg reload

# --- Unified Notification ---
notify-send -a "System" \
  -h "string:x-canonical-private-synchronous:sys-theme" \
  -t 2500 \
  "$TITLE" \
  "$MSG"
