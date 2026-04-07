#!/bin/sh
# Handles both Sway and Mako theme symlinks

THEME_DIR="$HOME/.config/sway/themes"
MAKO_LINK="$HOME/.config/mako/theme_current"

case "$1" in
dark)
  ln -sf "$THEME_DIR/sway_dark.conf" "$THEME_DIR/sway_current.conf"
  ln -sf "$THEME_DIR/mako_dark.conf" "$MAKO_LINK"
  MSG="Dark Mode"
  ;;
light)
  ln -sf "$THEME_DIR/sway_light.conf" "$THEME_DIR/sway_current.conf"
  ln -sf "$THEME_DIR/mako_light.conf" "$MAKO_LINK"
  MSG="Light Mode"
  ;;
esac

# 1. Update Mako colors live
makoctl reload

# 2. Update Sway colors live
swaymsg reload

# 3. Send the confirmation notification
# -t 2000 sets a 2-second timeout for a cleaner exit
notify-send -t 2000 "System" "Theme switched to $MSG"
