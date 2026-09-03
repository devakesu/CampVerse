#!/usr/bin/env bash
set -eo pipefail

CMD="$1"

# Ensure DBUS session bus and GNOME Keyring are active for libsecret on Linux
if [[ "$(uname)" == "Linux" ]]; then
  export DBUS_SESSION_BUS_ADDRESS="unix:path=/tmp/dbus-session.sock"
  if ! dbus-send --session --dest=org.freedesktop.DBus --type=method_call /org/freedesktop/DBus org.freedesktop.DBus.ListNames >/dev/null 2>&1; then
    rm -f /tmp/dbus-session.sock
    dbus-daemon --session --address="$DBUS_SESSION_BUS_ADDRESS" --fork >/dev/null 2>&1 || true
  fi
  if ! pgrep -f gnome-keyring-daemon >/dev/null 2>&1; then
    gnome-keyring-daemon --start --components=secrets >/dev/null 2>&1 || true
  fi
fi

# When flutter is invoked to run or test, inject in-memory Infisical defines
if [[ "$CMD" == "run" || "$CMD" == "test" ]]; then
  DEFINES=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && DEFINES+=("$line")
  done < <(infisical export --path=/public --format=json 2>/dev/null | jq -r '.[] | "--dart-define=\(.key)=\(.value)"' 2>/dev/null || true)

  shift # Remove 'run' or 'test'
  exec flutter "$CMD" "${DEFINES[@]}" "$@"
else
  exec flutter "$@"
fi
