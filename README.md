# sinkswitch
### Pipewire/Wireplumber output swichter for Scratchpads in [Hyprland](https://hypr.land/) and other WM's with scratchpad support.
![Showcase](/example.jpg)

## :beginner: Description
The tool shows a little menu to switch between your pipewire audio outputs(sinks). It was written with Hyprland and it's [Special Workspace's (aka scratchpad's)](https://wiki.hypr.land/Configuring/Dispatchers/#special-workspace) in mind, but should be usable with any other compositor that got a scratchpad feature too like Sway etc., or even just from your terminal if you wish to.
<br/>

## :dna: Dependencies
Using [Hyprland](https://hypr.land/): As most modern distro's already use pipewire & wireplumber as their audio backend/frontend, the only thing you might need to install as dependency is [fzf](https://github.com/junegunn/fzf).

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

### Hyprland Keybinding
If you want to use a keybinding to call and open the menu use something like the following in your **`hyprland.conf`**. Tweak the **move** coordinates and **size** of the displayed scratchpad to fit your needs.
This example uses a extra macro key my keyboard has and uses my 3440x1440px monitor.
```sh
bind = , XF86Tools, exec, [workspace special:kitty-sinkswitch; monitor DP-1; float; move 2936 64; size 480 160] kitty --class kitty-scratch -e ~/scripts/sinkswitch.sh -exclude 46
```
### Waybar Integration
If you want to use a button on your waybar(e.g. from your volume control), this can easily done by linking the script and executing it with **`hyprctl dispatch`**.

Example:
```sh
"pulseaudio": {
        "format": "{icon} {volume}%",
        "tooltip": false,
        "format-muted": " Muted",
        "on-click": "hyprctl dispatch exec \"[workspace special:kitty-sinkswitch; monitor DP-1; float; move 2916 64; size 500 180] kitty --class kitty-scratch -e ~/scripts/sinkswitch.sh -exclude 46\"",
        "on-scroll-up": "pamixer -i 5",
        "on-scroll-down": "pamixer -d 5",
        "scroll-step": 5,
        "max-length": 10,
        "states": {
        		"low!": 30,
        		"critical!": 15
        },
```

## :no_entry_sign: Exclude/Hide certain outputs(sinks)
If you want to hide one or more outputs(sinks) from your menu you can do so by calling the script with the **`-exclude`** flag followed by a comma seperated list of sink id's to hide.
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
You can get the **`node.name`** and current **`node.description`** with
```sh
pw-cli list-objects Node
```
## :scroll: Changelog and current state (yyyy-mm-dd)

- [x] 2025-12-28 | v1.0 | Upload the script and create a suitable README


## :sparkling_heart: Thank you
Thank's go out to [Sebastiaan76](https://github.com/Sebastiaan76) and his work on [waybar_wireplumber_audio_changer](https://github.com/Sebastiaan76/waybar_wireplumber_audio_changer) for the idea.

### :cyclone: Disclamer

> **This is a private project and i am not a developer. I am only sharing this because it might help others. If you want to fork it, go ahead! If you find any errors or got suggestions, please let me know!**
