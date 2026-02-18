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

for d in */; do
  name="${d%/}"
  case "$name" in
    common|resources) continue ;;
    *) ;;
  esac

  # Check if any file in ~ is a symlink into this package
  target=$(find "$name" -type f ! -name '.placeholder' -print -quit 2>/dev/null)
  [ -z "$target" ] && continue
  relative="${target#"$name"/}"
  if [ -L "$HOME/$relative" ]; then
    resolved=$(readlink -f "$HOME/$relative" 2>/dev/null || true)
    if [[ "$resolved" == "$repo_dir/"* ]]; then
      stowed+=("$name")
    fi
  fi
done

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

targets=$($common_stowed && collect_targets common || true; for s in "${stowed[@]}"; do collect_targets "$s"; done)

# Unstow everything first (removes symlinks)
if $common_stowed; then
  stow -D common
  echo -e "Unstowed ${cyan}common${reset}"
fi
for s in "${stowed[@]}"; do
  stow -D "$s"
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
        || for s in "${stowed[@]}"; do cp "$repo_dir/$s/$f" "$HOME/$f" 2>/dev/null && break; done
      rm "$HOME/$f.bak"
      echo -e "  ${cyan}copied${reset}   ~/$f ${dim}(from repo, .bak removed)${reset}"
    fi
  else
    # No .bak — ask whether to copy from repo or skip entirely
    if [ -z "$auto_nobak" ]; then
      echo -e "${yellow}No backup:${reset} ~/$f"
      echo -e "  ${cyan}c${reset})opy from repo  ${cyan}C${reset})opy all  ${dim}s${reset})kip  ${dim}S${reset})kip all"
      while true; do
        read -rp "  > " choice </dev/tty
        case "$choice" in
          c) action="copy"; break ;;
          C) action="copy"; auto_nobak="copy"; break ;;
          s) action="skip"; break ;;
          S) action="skip"; auto_nobak="skip"; break ;;
          *) echo -e "  ${dim}c / C / s / S${reset}" ;;
        esac
      done
    else
      action="$auto_nobak"
    fi

    if [ "$action" = "copy" ]; then
      mkdir -p "$(dirname "$HOME/$f")"
      cp "$repo_dir/common/$f" "$HOME/$f" 2>/dev/null \
        || for s in "${stowed[@]}"; do cp "$repo_dir/$s/$f" "$HOME/$f" 2>/dev/null && break; done
      echo -e "  ${cyan}copied${reset}   ~/$f ${dim}(from repo)${reset}"
    else
      echo -e "  ${dim}skipped${reset} ~/$f"
    fi
  fi
  restored=$((restored + 1))
done 3<<< "$targets"

echo ""
echo -e "${green}Done.${reset} Config files are now standalone copies — no longer linked to ${dim}~/dotfiles/${reset}"
