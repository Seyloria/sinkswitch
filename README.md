# sinkswitch
### Pipewire/Wireplumber output swichter for Scratchpads in [Hyprland](https://hypr.land/) and other WM's with scratchpad support.
![Showcase](/example.jpg)

## :beginner: Description
The tool spawns a little menu running in your terminal to switch between your pipewire audio outputs(sinks). It was written with Hyprland and it's [Special Workspace's (aka scratchpad's)](https://wiki.hypr.land/Configuring/Dispatchers/#special-workspace) in mind, but should be usable with any other compositor that got a scratchpad feature aswell(Sway etc.), or you can run it just in the terminal if you wish to.
<br/>

## :dna: Dependencies
Using [Hyprland](https://hypr.land/): As most modern distro's already use pipewire & wireplumber as their audio backend/frontend, the only thing you might need to install as a dependency is [fzf](https://github.com/junegunn/fzf).

### List of dependencies
- **Hyprland** or any other compositor that makes use of some sort of scratchpad
- **pipewire:** The core audio system on most modern distro's
- **wireplumber:** The default pipewire session manager most modern distro's use
- **wpctl:** CLI tool that let's you work with wireplumber, comes with wireplumber by default
- **terminal:** I use kitty, but any should work, just use what you already have
- **[fzf](https://github.com/junegunn/fzf):** The tool used to dislpay the fancy menu. Can be found in nearly every modern distro's package repository and manager
<br/>

## :floppy_disk: Installation
Open a terminal and navigate to where you want to store the script (Example: **`~/scripts/`** =  somewhere inside your home directory would be suitable).
Then use curl **or** wget to download the script:
```sh
curl -O  https://raw.githubusercontent.com/Seyloria/sinkswitch/main/sinkswitch.sh
```
```sh
wget https://raw.githubusercontent.com/Seyloria/sinkswitch/main/sinkswitch.sh
```
### Make the script executable
```sh
chmod +x sinkswitch.sh
```
<br/>

## :link: Scratchpad Config

### hyprland.conf
Add this windowrule to your **`hyprland.conf`**. Tweak the **monitor**, **move** coordinates and **size** to adjust the displayed scratchpad to fit your needs.
This example uses a 3440x1440px monitor and scratchpad size only needs to fit 3 menu entries. The menu is spawned in the top right of the screen.

### Hyprland since v0.53.0
```
windowrule = match:class kitty-sinkswitch, monitor DP-1, float on, move 2936 64, size 480 160
```

### Hyprland till v0.52.2
```
windowrule = monitor DP-1, float, move 2936 64, size 480 160, class:kitty-sinkswitch
```
### Keybinding
This example uses an extra macro key on the keyboard, but you can assign it to any key of your choosing.
```
bind = , XF86Tools, exec, [workspace special:sinkswitch] kitty --class kitty-sinkswitch -e ~/scripts/sinkswitch.sh -exclude 46
```
### Waybar Integration
If you want to use a button on your waybar(e.g. from your volume control) to open the menu, this can easily be done by executing the script with **`hyprctl dispatch`**.

Example:
```sh
"pulseaudio": {
        "format": "{icon} {volume}%",
        "tooltip": false,
        "format-muted": " Muted",
        "on-click": "hyprctl dispatch exec \"[workspace special:sinkswitch] kitty --class kitty-sinkswitch -e ~/scripts/sinkswitch.sh -exclude 46\"",
        "on-scroll-up": "pamixer -i 5",
        "on-scroll-down": "pamixer -d 5",
        "scroll-step": 5,
        "max-length": 10,
        "states": {
        		"low!": 30,
        		"critical!": 15
        },
},
```
<br/>

## Command-line Options

All available options and flags:

| Option | Description |
|--------|-------------|
| `-h` | Show the help menu with all available options |
| `-exclude <ids>` | Hide device IDs from the menu (comma-separated list). Run `wpctl status` to find IDs. |
| `-nick` | Show sink nicknames instead of descriptions (adds `--nick` flag to wpctl) |
| `-sync` | Migrate active audio streams to the newly selected sink immediately |
| `-notify` | Send a desktop notification (using notify-send) when sink changes |
| `-notify-hypr` | Send a Hyprland native notification (using hyprctl) when sink changes |

### Examples:
```sh
# Show help menu
sinkswitch -h

# Create a menu with excluded sinks and send notification
sinkswitch -exclude 46,63 -notify

# Display sinks with nicknames
sinkswitch -nick

# Switch sink and migrate active streams
sinkswitch -sync

# Use Hyprland notification
sinkswitch -notify-hypr

# Combine multiple options
sinkswitch -exclude 45,60 -sync -notify-hypr -nick
```


## :no_entry_sign: Exclude/Hide certain outputs(sinks)
If you want to hide one or more outputs(sinks) from your menu, you can do so by calling the script with the **`-exclude`** flag, followed by a comma seperated list of sink id's to hide.
Show all sinks and their id's:
```sh
wpctl status
```
**Output:**
```
Audio
 ├─ Devices:
 │      49. Navi 21/23 HDMI/DP Audio Controller [alsa]
 │      50. Vocaster One USB                    [alsa]
 │      51. Radeon High Definition Audio Controller [alsa]
 │      52. Ryzen HD Audio Controller           [alsa]
 │  
 ├─ Sinks:
 │      46. Yamaha RX-V583                      [vol: 1.00]
 │      63. 📺 AV Receiver - Yamaha RX-V583   [vol: 0.60]
 │      64. 🎧 Headphones - Vocaster One      [vol: 0.85]
 │  *   65. 🔈 Desktop Speakers - Nubert A-125 [vol: 0.20]
 │  
```
Then use the id's you want to hide and include them when calling the script:<br/>
Example: **`~/scripts/sinkswitch.sh -exclude 46,63`**

<br/>

## :abc: Rename outputs (sinks)
If you hate the often weird and generic names a sink has, you can do this by using a wireplumber rule to change the **`node.description`**.
Make a new file named like this in the following directory:

**`/home/username/.config/wireplumber/wireplumber.conf.d/50-rename-outputs.conf`**

**Reboot** or use **`systemctl --user restart wireplumber`** to apply the changes.

You can get the **`node.name`** and current **`node.description`** with
```sh
pw-cli list-objects Node
```

**Example `50-rename-outputs.conf`:**
```
monitor.alsa.rules = [
  {
    matches = [
      # This matches the value of the 'node.name' property of the node.
      {
        node.name = "alsa_output.usb-Focusrite_Vocaster_One_USB_V1V15632A08AAF-00.analog-surround-40"
      }
    ]
    actions = {
      # Apply all the desired node specific settings here.
      update-props = {
        node.description = "🎧 Headphones - Vocaster One"
      }
    }
  }
  {
    matches = [
      # This matches the value of the 'node.name' property of the node.
      {
        node.name = "alsa_output.pci-0000_03_00.1.hdmi-surround"
      }
    ]
    actions = {
      # Apply all the desired node specific settings here.
      update-props = {
        node.description = "📺 AV Receiver - Yamaha RX-V583"
      }
    }
  }
  {
    matches = [
      # This matches the value of the 'node.name' property of the node.
      {
        node.name = "alsa_output.pci-0000_13_00.6.iec958-stereo"
      }
    ]
    actions = {
      # Apply all the desired node specific settings here.
      update-props = {
        node.description = "🔈 Desktop Speakers - Nubert A-125"
      }
    }
  }
]
```

## :scroll: Changelog and current state (yyyy-mm-dd)

- [x] 2026-03-24 | v1.4 | Adds -nick parameter to display sink nicknames
- [x] 2026-03-24 | v1.3 | Improves CLI usability with help menu and better argument handling
- [x] 2026-03-24 | v1.2 | Adds notification support for sink switching (notify-send and Hyprland)
- [x] 2026-03-23 | v1.1 | Adds option to sync active streams when switching sink
- [x] 2025-12-28 | v1.0 | Upload the script and create a suitable README


## :sparkling_heart: Thank you
Thank's go out to [Sebastiaan76](https://github.com/Sebastiaan76) and his work on [waybar_wireplumber_audio_changer](https://github.com/Sebastiaan76/waybar_wireplumber_audio_changer) for the idea.

### :cyclone: Disclamer

> **This is a private project and i am not a developer. I am only sharing this because it might help others. If you want to fork it, go ahead! If you find any errors or got suggestions, please let me know!**
