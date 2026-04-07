#!/bin/sh
# Unified Theme & Environment Switcher for Sway/Mako/Gammastep
# Controlled by Darkman

# --- Configuration ---
THEME_DIR="$HOME/.config/sway/themes"
MAKO_LINK="$HOME/.config/mako/theme_current"

# Temperature Settings
NIGHT_TMP=3500
DAY_TMP=4500

case "$1" in
dark)
  # 1. System Appearance (GTK & Color Scheme)
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

  # 2. Config Symlinks
  ln -sf "$THEME_DIR/sway_dark.conf" "$THEME_DIR/sway_current.conf"
  ln -sf "$THEME_DIR/mako_dark.conf" "$MAKO_LINK"

  # 3. Night Light (Gammastep)
  pkill gammastep
  gammastep -O $NIGHT_TMP &

  # 4. Notification Content
  TITLE="󰖔  evening"
  MSG="dark theme • $NIGHT_TMP K"
  ;;

light)
  # 1. System Appearance
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'

  # 2. Config Symlinks
  ln -sf "$THEME_DIR/sway_light.conf" "$THEME_DIR/sway_current.conf"
  ln -sf "$THEME_DIR/mako_light.conf" "$MAKO_LINK"

  # 3. Night Light
  pkill gammastep
  gammastep -O $DAY_TMP &

  # 4. Notification Content
  TITLE="󰖙  daylight"
  MSG="light theme • $DAY_TMP K"
  ;;
esac

# --- Apply Changes Live ---
makoctl reload
swaymsg reload

# --- Unified Notification ---
# Uses synchronous hint to update the same bubble instead of stacking
notify-send -a "System" \
  -h "string:x-canonical-private-synchronous:sys-theme" \
  -t 2500 \
  "$TITLE" \
  "$MSG"
