#!/usr/bin/env bash

CONFIG_PATH="$XDG_DATA_HOME/chezmoi"
INIT_SCRIPT="$CONFIG_PATH/install.bash"

command -v bw && command -v gh &> /dev/null || sudo pacman -Syu --needed --noconfirm bitwarden-cli github-cli

echo "Dependencies installed..."

items=$(BW_SESSION=$(bw login --raw) bw list items --search bootstrap)
count=$(echo "$items" | jq '. | length')

if [ "$count" -ne 1 ]; then
    echo "More than one auth item was found. Check the password manager."
    exit 1
fi

GH_TOKEN=$(echo "$items" | jq -r '.[0].login.password') gh repo clone dotfiles "$CONFIG_PATH"

chmod +x "$INIT_SCRIPT" && "$INIT_SCRIPT"
