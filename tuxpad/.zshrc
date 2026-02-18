source ~/.zshrc-common

## ThinkPad T480 ##

# Toggle touchpad on/off (works with KDE Plasma on Wayland)
function touchpad() {
  local dbus_path="/org/kde/KWin/InputDevice"
  local dbus_iface="org.kde.KWin.InputDevice"
  local dev

  # Find the touchpad device dynamically
  for dev in $(qdbus6 org.kde.KWin $dbus_path org.freedesktop.DBus.Properties.Get org.kde.KWin.InputDeviceManager devicesSysNames); do
    local is_tp=$(qdbus6 org.kde.KWin $dbus_path/$dev org.freedesktop.DBus.Properties.Get $dbus_iface touchpad 2>/dev/null)
    [[ "$is_tp" == "true" ]] || continue

    local current=$(qdbus6 org.kde.KWin $dbus_path/$dev org.freedesktop.DBus.Properties.Get $dbus_iface enabled)
    if [[ "$current" == "true" ]]; then
      qdbus6 org.kde.KWin $dbus_path/$dev org.freedesktop.DBus.Properties.Set $dbus_iface enabled false
      echo "Touchpad \e[31mdisabled\e[0m"
    else
      qdbus6 org.kde.KWin $dbus_path/$dev org.freedesktop.DBus.Properties.Set $dbus_iface enabled true
      echo "Touchpad \e[31me\e[33mn\e[32ma\e[36mb\e[34ml\e[35me\e[31md\e[0m"
    fi
    return 0
  done

  echo "\e[31mNo touchpad device found\e[0m" >&2
  return 1
}
alias trackpad=touchpad

# Run purrfetch on new shell sessions
purrfetch
