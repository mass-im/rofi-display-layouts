#!/usr/bin/env bash

# Directory where layouts are stored
LAYOUT_DIR="$HOME/.config/rofi-displays/.layout/"

restart_wm() {
  echo 'awesome.restart()' | awesome-client
}

# Echo's the xrandr command for the currently active setup
current_command_layout() {
  command_output="xrandr"

  i=0
  for part in $(xrandr --listactivemonitors | tail -n +2); do
    if (( i % 4 == 2 )); then
      width="${part%%/*}"
      height="${part%/*}"
      height="${height#*x}"

      # Swap widht / height when rotation is not 'normal'
      if [ "$rotation" != "normal" ] ; then
        tmp_height=$height
        height=$width
        width=$tmp_height
      fi

      mode_setting="$width"
      mode_setting+="x"
      mode_setting+="$height"
      command_output+=" --mode $mode_setting"

      pos="${part#*+}"
      pos=$(echo "$pos" | tr + x)
      command_output+=" --pos $pos"
    elif (( i % 4 == 1 )); then
      is_primary=0
      name="${part:1}"
      if [[ $(echo "$part" | grep -i '*') != "" ]]; then
        is_primary=1
        name="${part:2}"
      fi

      command_output+=" --output '$name'"
      if [ $is_primary == 1 ]; then
        command_output+=" --primary"
      fi

      # Grab rotation for non-primary displays
      if [ $is_primary == 0 ]; then
        rotation=$(xrandr --query --verbose | grep $name | cut -d ' ' -f 5)
        command_output+=" --rotation $rotation"
      else
        rotation="normal"
      fi
    fi
    i=$((i + 1))
  done

  echo $command_output
}

save_current_layout() {
  layout_name=$(rofi -dmenu -theme-str 'listview { enabled: false;}' -p "Enter layout name >")

  if [ -n "$layout_name" ]; then
    echo "Creating layout $layout_name"
    current_command_layout > "$LAYOUT_DIR/$layout_name"
    chmod +x "$LAYOUT_DIR/$layout_name"
  fi
}

remove_layout_menu() {
  while true; do
    layout_name=$(echo "${layouts[@]} --- Exit" | tr ' ' '\n' | rofi -dmenu -i -no-custom -p "Deleting layout")

    if [ "$layout_name" == "Exit" ] || [ -z "$layout_name" ]; then
      exit
    elif [ "$layout_name" != "Choose layout" ]; then
      echo "Removing $layout_name"
      rm "$LAYOUT_DIR/$layout_name"
      break
    fi
  done
}

while true; do
  layouts=$(ls "$LAYOUT_DIR")
  menu=$(echo "${layouts[@]} --- Save Remove Exit" | tr ' ' '\n' | rofi -dmenu -i -p "Choose layout")

  if [ "$menu" == "Exit" ] || [ -z "$menu" ]; then
    exit
  elif [ "$menu" == "Save" ]; then
    save_current_layout
  elif [ "$menu" == "Remove" ]; then
    remove_layout_menu
  elif [ "$menu" != "---" ]; then
    echo $menu
    source "$LAYOUT_DIR/$menu"
    restart_wm
    exit
  fi
done
