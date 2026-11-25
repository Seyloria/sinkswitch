#!/usr/bin/env bash

# Version 2.0
# written by Seyloria

exclude_ids=()

notify_mode="none"
use_nick=false
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
      echo -e "\033[32mVersion 2.0 | written by Seyloria\033[0m"
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
                                Example markers/symbols: ${example_markers[*]}
                                Example: $(basename "$0") -dflag ${example_markers[8]}

  -exclude <ids>               Hide specific device IDs (comma-separated).
                                Run 'wpctl status' to find the IDs to hide.
                                Example: $(basename "$0") -exclude 45,60
                                For more persistence see "EXCLUDE SINKS:" below.

  -nick                        Show sink nicknames instead of descriptions.

  -notify                      Send notification using notify-send (Libnotify).
  
  -notify-hypr                 Send notification using hyprctl (Hyprland Native).


EXAMPLES:
  # Open selection menu
  $ $(basename "$0")
  
  # Exclude specific devices and send notification
  $ $(basename "$0") -exclude 3,5 -notify
  
  # Change prompt and selection color, when using nicks as output names
  $ $(basename "$0") -color-prompt green -color-selection magenta -nick

  # Change prompt color and default sink marker/symbol
  $ $(basename "$0") -color-prompt  magenta -dflag ⋗

EXCLUDE SINKS:
                               Put a file called excludes.conf next to the script, or at ~/.config/sinkswitch/excludes.conf
                               Find the sink(s) <id> to hide with: wpctl status
                               Find the node.name with: wpctl inspect <id> | grep node.name
                               Copy the node.name value into the excludes.conf
                               Hides sinks by node.name, one per line. Lines starting with # are comments.
                               Unlike IDs, this method via node.name survives reboots.

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
    -notify)
      notify_mode="normal"
      shift
      ;;
    -notify-hypr)
      notify_mode="hyprland"
      shift
      ;;
    -nick)
      use_nick=true
      shift
      ;;
    -color-selection)
      if [[ -z "$2" || "$2" == -* ]]; then
        echo "Error: -color-selection requires a color"
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
        echo "Error: -color-prompt requires a color"
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

# Load excluded node.name values (one per line, '#' starts a comment).
# Unlike IDs, node.name survives reboots and replugging.
# Search order: next to the script (symlinks resolved), then the config dir.
# The first file found is used.
script_dir="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
exclude_file=""
for f in "$script_dir/excludes.conf" "${XDG_CONFIG_HOME:-$HOME/.config}/sinkswitch/excludes.conf"; do
    if [[ -f "$f" ]]; then
        exclude_file="$f"
        break
    fi
done

declare -A exclude_names

if [[ -n "$exclude_file" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line%%#*}"
        line="${line#"${line%%[![:space:]]*}"}"   # trim leading whitespace
        line="${line%"${line##*[![:space:]]}"}"   # trim trailing whitespace
        [[ -n "$line" ]] && exclude_names["$line"]=1
    done < "$exclude_file"
fi

# Reads a property value from `wpctl inspect` output.
# Usage: get_prop <property> <inspect output>
get_prop() {
    sed -n "s/^[ *]*$1 = \"\(.*\)\"/\1/p" <<< "$2"
}

# Stores all the sinks
declare -A sinks

# Stores the currently active default sink ID
default_sink=$(wpctl inspect @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk 'NR==1 {gsub(",", "", $2); print $2}')

# Collect candidate IDs from the "Sinks:" and "Filters:" sections of the Audio block.
# Some devices (e.g. Focusrite Vocaster One with UCM profile) expose their usable
# sinks as filter/loopback nodes, which wpctl lists under "Filters:" instead of "Sinks:".
# Each candidate is then validated with `wpctl inspect`: only nodes with
# media.class = "Audio/Sink" are kept. This drops raw parent nodes
# (Audio/Sink/Internal), sources, and .split stream nodes, which
# `wpctl set-default` refuses anyway.
while read -r id; do
    info=$(wpctl inspect "$id" 2>/dev/null)
    grep -qE 'media\.class = "Audio/Sink"[[:space:]]*$' <<< "$info" || continue

    node_name=$(get_prop node.name "$info")
    [[ -n "${exclude_names[$node_name]}" ]] && continue

    name=""
    [[ "$use_nick" == true ]] && name=$(get_prop node.nick "$info")
    [[ -z "$name" ]] && name=$(get_prop node.description "$info")
    [[ -z "$name" ]] && name="$node_name"

    sinks["$id"]="$name"
done < <(
  wpctl status |
  sed -n '/^Audio$/,/^Video$/p' |
  sed -n '/Sinks:/,/Sources:/p;/Filters:/,/Streams:/p' |
  sed -nE 's/^[^0-9]*([0-9]+)\. .*/\1/p'
)

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

# Set new default sink or on error exit with error code
wpctl set-default "$new_default" || exit 1

if [[ "$notify_mode" != "none" ]]; then
    send_notification "Default audio output switched to: ${sinks[$new_default]}"
fi
