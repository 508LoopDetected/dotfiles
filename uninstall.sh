#!/bin/bash
# Stow uninstaller — removes symlinks, restores backups or copies repo files into place
set -euo pipefail
cd "$(dirname "$0")"

# Colors
red="\e[31m"
green="\e[32m"
yellow="\e[33m"
blue="\e[34m"
purple="\e[35m"
cyan="\e[36m"
dim="\e[2m"
bold="\e[1m"
reset="\e[0m"

# Find stowed packages by checking for symlinks pointing into this repo
repo_dir=$(pwd)
stowed=()

if [ -d profiles ]; then
  for d in profiles/*/; do
    name="${d#profiles/}"
    name="${name%/}"

    # Check if any file in ~ is a symlink into this package
    target=$(find "profiles/$name" -type f ! -name '.placeholder' -print -quit 2>/dev/null)
    [ -z "$target" ] && continue
    relative="${target#profiles/$name/}"
    if [ -L "$HOME/$relative" ]; then
      resolved=$(readlink -f "$HOME/$relative" 2>/dev/null || true)
      if [[ "$resolved" == "$repo_dir/profiles/$name/"* ]]; then
        stowed+=("$name")
      fi
    fi
  done
fi

# Check common separately
common_stowed=false
if [ -L "$HOME/.zshrc-common" ]; then
  resolved=$(readlink -f "$HOME/.zshrc-common" 2>/dev/null || true)
  if [[ "$resolved" == "$repo_dir/"* ]]; then
    common_stowed=true
  fi
fi

if ! $common_stowed && [ ${#stowed[@]} -eq 0 ]; then
  echo -e "${dim}Nothing is stowed.${reset}"
  exit 0
fi

# Show what's stowed
echo -e "${bold}Currently stowed:${reset}"
$common_stowed && echo -e "  ${cyan}common${reset}"
for s in "${stowed[@]}"; do
  echo -e "  ${purple}${s}${reset}"
done
echo ""

read -rp "$(echo -e "${yellow}Uninstall and detach from stow?${reset} ${dim}[y/N]${reset} ")" confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  echo -e "${dim}Cancelled.${reset}"
  exit 0
fi
echo ""

# Collect all target paths from stowed packages
collect_targets() {
  local pkg="$1"
  if [ -d "$pkg" ]; then
    (cd "$pkg" && find . -type f ! -name '.placeholder' | sed 's|^\./||')
  fi
}

targets=$($common_stowed && collect_targets common || true; for s in "${stowed[@]}"; do collect_targets "profiles/$s"; done)

# Unstow everything first (removes symlinks)
if $common_stowed; then
  stow -D common
  echo -e "Unstowed ${cyan}common${reset}"
fi
for s in "${stowed[@]}"; do
  stow -d profiles -t "$HOME" -D "$s"
  echo -e "Unstowed ${purple}${s}${reset}"
done
echo ""

# Restore files — prefer .bak if it exists, otherwise copy from repo
auto=""
auto_nobak=""
restored=0

while IFS= read -r f <&3; do
  [ -z "$f" ] && continue

  if [ -e "$HOME/$f.bak" ]; then
    # .bak exists — ask whether to restore it or use repo version
    if [ -z "$auto" ]; then
      echo -e "${blue}Backup found:${reset} ~/$f.bak"
      echo -e "  ${green}r${reset})estore backup  ${green}R${reset})estore all backups  ${cyan}c${reset})opy from repo  ${cyan}C${reset})opy all from repo"
      while true; do
        read -rp "  > " choice </dev/tty
        case "$choice" in
          r) action="restore"; break ;;
          R) action="restore"; auto="restore"; break ;;
          c) action="copy"; break ;;
          C) action="copy"; auto="copy"; break ;;
          *) echo -e "  ${dim}r / R / c / C${reset}" ;;
        esac
      done
    else
      action="$auto"
    fi

    if [ "$action" = "restore" ]; then
      mkdir -p "$(dirname "$HOME/$f")"
      mv "$HOME/$f.bak" "$HOME/$f"
      echo -e "  ${green}restored${reset} ~/$f ${dim}(from .bak)${reset}"
    else
      mkdir -p "$(dirname "$HOME/$f")"
      cp "$repo_dir/common/$f" "$HOME/$f" 2>/dev/null \
        || for s in "${stowed[@]}"; do cp "$repo_dir/profiles/$s/$f" "$HOME/$f" 2>/dev/null && break; done
      rm "$HOME/$f.bak"
      echo -e "  ${cyan}copied${reset}   ~/$f ${dim}(from repo, .bak removed)${reset}"
    fi
  else
    # No .bak — file only exists because of stow; keep a copy or remove
    if [ -z "$auto_nobak" ]; then
      echo -e "${dim}No original:${reset} ~/$f"
      echo -e "  ${cyan}k${reset})eep copy  ${cyan}K${reset})eep all  ${red}r${reset})emove  ${red}R${reset})emove all"
      while true; do
        read -rp "  > " choice </dev/tty
        case "$choice" in
          k) action="copy"; break ;;
          K) action="copy"; auto_nobak="copy"; break ;;
          r) action="skip"; break ;;
          R) action="skip"; auto_nobak="skip"; break ;;
          *) echo -e "  ${dim}k / K / r / R${reset}" ;;
        esac
      done
    else
      action="$auto_nobak"
    fi

    if [ "$action" = "copy" ]; then
      mkdir -p "$(dirname "$HOME/$f")"
      cp "$repo_dir/common/$f" "$HOME/$f" 2>/dev/null \
        || for s in "${stowed[@]}"; do cp "$repo_dir/profiles/$s/$f" "$HOME/$f" 2>/dev/null && break; done
      echo -e "  ${cyan}kept${reset}     ~/$f ${dim}(copied from repo)${reset}"
    else
      echo -e "  ${red}removed${reset}  ~/$f"
    fi
  fi
  restored=$((restored + 1))
done 3<<< "$targets"

echo ""
echo -e "${green}Done.${reset} Config files are now standalone copies — no longer linked to ${dim}~/dotfiles/${reset}"
