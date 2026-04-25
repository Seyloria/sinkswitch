#!/usr/bin/env bash

# Version 1.6
# written by Seyloria

exclude_ids=()

sync_active=false
notify_mode="none"
wpctl_options=""
pcolor="cyan"
scolor="red"
dflag="▶" # Default flag marker with stable size, that don't break alignment.
valid_colors=(black red green yellow blue magenta cyan white)
example_markers=(⟫ ■ ★ ⦿ ✪ ▶ ⋙ ⤐ ⋗ ⸭ ✠ ※)

banner=$(cat <<'EOF'

 ▄▄▄▄ ▄▄ ▄▄  ▄▄ ▄▄ ▄▄  ▄▄▄▄ ▄▄   ▄▄ ▄▄ ▄▄▄▄▄▄ ▄▄▄▄ ▄▄ ▄▄ 
███▄▄ ██ ███▄██ ██▄█▀ ███▄▄ ██ ▄ ██ ██   ██  ██▀▀▀ ██▄██ 
▄▄██▀ ██ ██ ▀██ ██ ██ ▄▄██▀  ▀█▀█▀  ██   ██  ▀████ ██ ██ 
EOF
)

is_valid_color() {
  local c="$1"
  for v in "${valid_colors[@]}"; do
    [[ "$c" == "$v" ]] && return 0
  done
  return 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|-help)
      echo -e "\033[35m$banner\033[0m\n"
      echo -e "\033[32mVersion 1.6 | written by Seyloria and contributer AlejandroMinor\033[0m"
      echo -e "\033[32mProject: https://github.com/Seyloria/sinkswitch\033[0m"
      cat << EOF

USAGE:
  $(basename "$0") [OPTIONS]

OPTIONS:
  -h, -help                    Show this help menu
                         
  -color-prompt <color>        Choose what color your prompt(header) should have
                                Valid colors are: ${valid_colors[*]}

  -color-selection <color>     Choose what color your selection should have
                                Valid colors are: ${valid_colors[*]}

  -dflag <marker/symbol>       Choose a fixed-width marker/symbol for the current default sink
                                Example: $(basename "$0") -dflag ${example_markers[8]}

  -exclude <ids>               Hide specific device IDs (comma-separated).
                                Run 'wpctl status' to find the IDs to hide.
                                Example: $(basename "$0") -exclude 45,60

  -nick                        Show sink nicknames instead of descriptions.
                                Adds --nick flag to wpctl status.
                         
  -notify                      Send notification using notify-send (Libnotify).
  
  -notify-hypr                 Send notification using hyprctl (Hyprland Native).

  -sync                        Migrate active audio streams (Spotify, Browser, etc.)
                                to the new device immediately.

EXAMPLES:
  # Open selection menu
  $ $(basename "$0")
  
  # Exclude specific devices and send notification
  $ $(basename "$0") -exclude 3,5 -notify
  
  # Change sink and migrate streams with Hyprland alert
  $ $(basename "$0") -sync -notify-hypr

  # Change prompt and selection color, when using nicks as output names
  $ $(basename "$0") -color-prompt green -color-selection magenta -nick

  # Change prompt color and default sink marker/symbol
  $ $(basename "$0") -color-prompt  magenta -dflag ⋗

EOF
      exit 0
      ;;
    -exclude)
      if [[ -z "$2" || "$2" == -* ]]; then
        echo "Error: The -exclude option requires a list of IDs"
        echo "Tip: Run 'wpctl status' to see the IDs"
        echo "Example: $(basename "$0") -exclude 45,60"
        exit 1
      fi
      IFS=',' read -ra exclude_ids <<< "$2"
      shift 2
      ;;
    -sync)
      sync_active=true
      shift
      ;;
    -notify)
      notify_mode="normal"
      shift
      ;;
    -notify-hypr)
      notify_mode="hyprland"
      shift
      ;;
    -nick)
      wpctl_options="--nick"
      shift
      ;;
    -color-selection)
      if [[ -z "$2" || "$2" == -* ]]; then
        echo "Error: -selection requires a color"
        echo "Available colors: ${valid_colors[*]}"
        exit 1
      fi

      if ! is_valid_color "$2"; then
        echo "Error: Invalid color '$2'"
        echo "Available colors: ${valid_colors[*]}"
        exit 1
      fi

      scolor="$2"
      shift 2
      ;;
    -color-prompt)
      if [[ -z "$2" || "$2" == -* ]]; then
        echo "Error: -prompt requires a color"
        echo "Available colors: ${valid_colors[*]}"
        exit 1
      fi
      
      if ! is_valid_color "$2"; then
        echo "Error: Invalid color '$2'"
        echo "Available colors: ${valid_colors[*]}"
        exit 1
      fi

      pcolor="$2"
      shift 2
      ;;
    -dflag)
      if [[ -z "$2" || "$2" == -* ]]; then
        echo "Error: -dflag requires a fixed-width marker/symbol"
        echo "Examples: ${example_markers[*]}"
        exit 1
      fi
      dflag="$2"
      shift 2
      ;;
    *)
      echo "Error: Unknown option '$1'"
      echo "Use '$(basename "$0") -help' to see available options"
      exit 1
      ;;
  esac
done

sync_active_streams() {
    local target_id="$1"
    wpctl status $wpctl_options | sed -n '/Streams:/,$p' | grep -E '[0-9]+\.' | awk -F'.' '{print $1}' | tr -d '[:space:]' | while read -r stream_id; do
        if [[ -n "$stream_id" ]]; then
            wpctl set-id "$stream_id" "$target_id" 2>/dev/null
        fi
    done
}

send_notification() {
    local message="$1"
    if [[ "$notify_mode" == "hyprland" ]]; then
        hyprctl notify 1 3500 "rgb(89b4fa)" " Sink Switcher: $message"
    elif [[ "$notify_mode" == "normal" ]]; then
        notify-send "Sink Switcher" "$message" --urgency=low --expire-time=2000 -i audio-speakers-symbolic 2>/dev/null
    fi
}

is_excluded() {
  local id="$1"
  for x in "${exclude_ids[@]}"; do
    [[ "$id" == "$x" ]] && return 0
  done
  return 1
}

# Stores all the sinks
declare -A sinks

# Stores the currently active default sink ID
default_sink=""


# Parse wpctl status output to populate sinks array and find default
# Reads each line of the filtered sink section, extracts the sink ID and name,
# and sets `default_sink` if the line contains the '*' marker.
while IFS= read -r line; do
    # Match lines with optional * + number + name
    if [[ $line =~ \**[[:space:]]*([0-9]+)\.\ ([^[]+) ]]; then
        id="${BASH_REMATCH[1]}"
        name="${BASH_REMATCH[2]}"
        sinks["$id"]="$name"
        # Check for * somewhere before the number in the line
        if [[ $line =~ \* ]]; then
            default_sink="$id"
        fi
    fi
done < <(wpctl status $wpctl_options |
sed -n '
  /^Audio$/,/^[A-Z]/ {
    /^[[:space:]]*├─ Sinks:/ {
      :loop
      n
      /^ │[[:space:]]*[0-9*]/ p
      /^ │[[:space:]]*$/ q
      b loop
    }
  }
')

# Builds the fzf selection (stable sorted version)
fzf_input=()

while IFS=$'\t' read -r id name; do
    is_excluded "$id" && continue

    flag=" "
    [[ "$id" == "$default_sink" ]] && flag="${dflag}"

    fzf_input+=("$id|$flag | $name")
done < <(
  for i in "${!sinks[@]}"; do
    printf "%s\t%s\t%s\n" "$i" "${sinks[$i]}" "${sinks[$i]//[^[:alnum:] ]/}"
  done | LC_ALL=C sort -t$'\t' -k3,3 | cut -f1-2
)

# Displays the fzf menu
selected=$(printf '%s\n' "${fzf_input[@]}" | fzf \
  --delimiter='|' \
  --with-nth=2.. \
  --color="prompt:${pcolor},fg+:${scolor}:bold" \
  --prompt="  (✿◠‿◠) Select Your Audio Output (◕‿◕✿)" \
  --no-preview --disabled --layout=reverse --border=none --no-info \
  --bind "change:clear-query")

[[ -z "$selected" ]] && exit 0  # user cancelled

# Extract the selected and new default sink ID
new_default="${selected%%|*}"

# Set new default sink
wpctl set-default "$new_default"

if [ "$sync_active" = true ]; then
    sync_active_streams "$new_default"
fi

if [[ "$notify_mode" != "none" ]]; then
    send_notification "Default audio output switched to: ${sinks[$new_default]}"
fi
