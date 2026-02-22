#!/usr/bin/env bash

CONFIG_PATH="$XDG_DATA_HOME/chezmoi"
INIT_SCRIPT="$CONFIG_PATH/install.bash"
ITEM_ID="${1:-c32a8f1d-75b7-4a72-bb98-b3f50174df81}"

log() {
    local level="$1"; shift
    local msg="[$(date '+%Y-%m-%dT%H:%M:%S')] [$level] $*"
    [[ "$level" == "ERROR" ]] && echo "$msg" >&2 || echo "$msg"
}

declare -A deps=([bw]="bitwarden-cli" [gh]="github-cli" [jq]="jq")
declare -A status
for cmd in "${!deps[@]}"; do
    command -v "$cmd" &>/dev/null && status[$cmd]=0 || status[$cmd]=1
done

to_install=()
for cmd in "${!status[@]}"; do
    [[ "${status[$cmd]}" -eq 1 ]] && to_install+=("${deps[$cmd]}")
done

if [[ ${#to_install[@]} -gt 0 ]]; then
    log INFO "Installing: ${to_install[*]}"
    sudo pacman -Syu --needed --noconfirm "${to_install[@]}"
fi

bw_status=$(bw status | jq -r '.status')
case "$bw_status" in
    unauthenticated)
        session=$(bw login --raw) || { log ERROR "Bitwarden login failed"; exit 1; }
        ;;
    locked)
        session=$(bw unlock --raw) || { log ERROR "Bitwarden unlock failed"; exit 1; }
        ;;
    unlocked)
        session="$BW_SESSION"
        ;;
    *)
        log ERROR "Unknown Bitwarden status: '$bw_status'"
        exit 1
        ;;
esac

token=$(BW_SESSION="$session" bw get password "$ITEM_ID") || { log ERROR "Failed to retrieve password for item $ITEM_ID"; exit 1; }

GH_TOKEN=${token} gh repo clone dotfiles "$CONFIG_PATH"

chmod +x "$INIT_SCRIPT" && "$INIT_SCRIPT"
