#!/bin/bash

set -e

device=$1

if [[ $device != "laptop" ]] && [[ $device != "desktop" ]] && [[ $device != "mac" ]]; then
  echo "Only 'laptop', 'desktop' or 'mac' option is supported!"
  exit 1
fi

common_path=$(cd common; pwd)
device_path=$(cd $device; pwd)

echo "Installing for '$device'..."

echo "Patching ~/.zshrc"
echo -e "\nsource $device_path/.zshrc_extensions" >> ~/.zshrc

if [[ $device != "mac" ]]; then
  if [ -d ~/.config/i3 ] || [ -L ~/.config/i3 ]; then
    echo "Renaming '~/.config/i3' to '~/.config/i3_bak'"
    mv ~/.config/i3 ~/.config/i3_bak
  fi
  ln -s $device_path/.config/i3 ~/.config/i3
fi

if [[ $device == "mac" ]]; then
  if [ -f ~/.yabairc ] || [ -L ~/.yabairc ]; then
    echo "Renaming '~/.yabairc' to '~/.yabairc_bak'"
    mv ~/.yabairc ~/.yabairc_bak
  fi
  ln -s $device_path/.yabairc ~/.yabairc

  if [ -f ~/.skhdrc ] || [ -L ~/.shkdrc ]; then
    echo "Renaming '~/.skhdrc' to '~/.shkdrc_bak'"
    mv ~/.skhdrc ~/.skhdrc_bak
  fi
  ln -s $device_path/.skhdrc ~/.skhdrc
fi

if [ -f ~/.vimrc ] || [ -L ~/.vimrc ]; then
  echo "Renaming '~/.vimrc' to '~/.vimrc.bak'"
  mv ~/.vimrc ~/.vimrc.bak
fi
ln -s $common_path/.vimrc ~/.vimrc

if [ -d ~/.config/nvim ] || [ -L ~/.config/nvim ]; then
  echo "Renaming '~/.config/nvim' to '~/.config/nvim_bak'"
  mv ~/.config/nvim ~/.config/nvim_bak
fi
ln -s $common_path/.config/nvim ~/.config/nvim

if [ -d ~/.config/mc ] || [ -L ~/.config/mc ]; then
  echo "Renaming '~/.config/mc' to '~/.config/mc_bak'"
  mv ~/.config/mc ~/.config/mc_bak
fi
ln -s $common_path/.config/mc ~/.config/mc

if [ -f ~/.wezterm.lua ] || [ -L ~/.wezterm.lua ]; then
  echo "Renaming '~/.wezterm.lua' to '~/.wezterm.lua.bak'"
  mv ~/.wezterm.lua ~/.wezterm.lua.bak
fi
ln -s $device_path/.wezterm.lua ~/.wezterm.lua

echo "Done."
