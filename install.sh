#!/bin/bash
# Stow installer — backs up conflicting files, then stows common + machine package
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

# Find machine packages (directories that aren't common, resources, or dotfiles)
machines=()
for d in */; do
  name="${d%/}"
  case "$name" in
    common|resources) continue ;;
    *) machines+=("$name") ;;
  esac
done

# Detect hostname and match to a package
this_host=$(cat /etc/hostname 2>/dev/null || hostnamectl --static 2>/dev/null || hostname 2>/dev/null || echo "")
machine=""

# Check if a package already matches this hostname
for m in "${machines[@]}"; do
  if [ "$m" = "$this_host" ]; then
    machine="$m"
    break
  fi
done

if [ -n "$machine" ]; then
  # Hostname matched — confirm or let them override
  echo -e "Detected ${purple}${machine}${reset} ${dim}(matches hostname)${reset}"
  read -rp "$(echo -e "Use this? ${dim}[Y/n/other]${reset} ")" confirm
  case "$confirm" in
    ""|[Yy]) ;; # keep it
    [Nn])
      # Show manual selector
      echo ""
      echo -e "${bold}Select machine:${reset}"
      select machine in "${machines[@]}" "Create new"; do
        [ -n "$machine" ] && break
        echo -e "${red}Invalid selection, try again.${reset}"
      done
      ;;
    *)
      # Typed a custom name
      machine="$confirm"
      ;;
  esac
else
  # No matching package — offer to create one or pick existing
  echo -e "${yellow}No package for${reset} ${purple}${this_host}${reset}"
  echo ""
  echo -e "${bold}Select machine:${reset}"
  select machine in "Create ${this_host}" "${machines[@]}" "Create other"; do
    [ -n "$machine" ] && break
    echo -e "${red}Invalid selection, try again.${reset}"
  done

  if [ "$machine" = "Create ${this_host}" ]; then
    machine="$this_host"
  elif [ "$machine" = "Create other" ]; then
    echo ""
    read -rp "$(echo -e "Machine name: ")" machine
  fi
fi

# Create the package directory if it doesn't exist
if [ ! -d "$machine" ]; then
  mkdir -p "$machine"
  echo "# No custom configs for this machine yet." > "$machine/.placeholder"
  echo -e "Created ${purple}${machine}/${reset} ${dim}(placeholder only)${reset}"
fi

# Detect if a different machine is already stowed and unstow it
repo_dir=$(pwd)
for m in "${machines[@]}"; do
  [ "$m" = "$machine" ] && continue
  # Check if any file in ~ is a symlink into this other package
  sample=$(find "$m" -type f ! -name '.placeholder' -print -quit 2>/dev/null)
  [ -z "$sample" ] && continue
  relative="${sample#"$m"/}"
  if [ -L "$HOME/$relative" ]; then
    resolved=$(readlink -f "$HOME/$relative" 2>/dev/null || true)
    if [[ "$resolved" == "$repo_dir/$m/"* ]]; then
      echo ""
      echo -e "${yellow}Switching from${reset} ${purple}${m}${reset} ${yellow}to${reset} ${purple}${machine}${reset}"
      stow -D "$m"
      echo -e "Unstowed ${purple}${m}${reset}"
      break
    fi
  fi
done

# Check if machine package has real files (anything besides .placeholder)
has_custom=false
if [ -d "$machine" ]; then
  real_files=$(find "$machine" -type f ! -name '.placeholder' | head -1)
  [ -n "$real_files" ] && has_custom=true
fi

echo ""
if $has_custom; then
  echo -e "Will install: ${cyan}common${reset} + ${purple}${machine}${reset}"
else
  echo -e "Will install: ${cyan}common${reset} ${dim}(no custom files in ${machine}/ yet)${reset}"
fi
echo ""

# Collect all target paths from both packages (excluding .placeholder)
collect_targets() {
  local pkg="$1"
  if [ -d "$pkg" ]; then
    (cd "$pkg" && find . -type f ! -name '.placeholder' | sed 's|^\./||')
  fi
}

targets=$(collect_targets common; $has_custom && collect_targets "$machine" || true)

# Resolve conflicts with existing files
auto=""
conflicts=0

while IFS= read -r f <&3; do
  [ -z "$f" ] && continue
  [ ! -e "$HOME/$f" ] && continue
  # Skip if already managed by stow (symlink or inside a symlinked directory)
  resolved=$(readlink -f "$HOME/$f" 2>/dev/null || true)
  [[ "$resolved" == "$repo_dir/"* ]] && continue

  conflicts=$((conflicts + 1))

  if [ -z "$auto" ]; then
    echo -e "${yellow}Conflict:${reset} ~/$f"
    echo -e "  ${green}b${reset})ackup  ${green}B${reset})ackup all  ${red}o${reset})verwrite  ${red}O${reset})verwrite all"
    while true; do
      read -rp "  > " choice </dev/tty
      case "$choice" in
        b) action="backup"; break ;;
        B) action="backup"; auto="backup"; break ;;
        o) action="overwrite"; break ;;
        O) action="overwrite"; auto="overwrite"; break ;;
        *) echo -e "  ${dim}b / B / o / O${reset}" ;;
      esac
    done
  else
    action="$auto"
  fi

  if [ "$action" = "backup" ]; then
    mkdir -p "$(dirname "$HOME/$f.bak")"
    mv "$HOME/$f" "$HOME/$f.bak"
    echo -e "  ${blue}backed up${reset} ~/$f ${dim}-> ~/$f.bak${reset}"
  else
    rm -rf "$HOME/$f"
    echo -e "  ${red}removed${reset}   ~/$f"
  fi
done 3<<< "$targets"

if [ "$conflicts" -eq 0 ]; then
  echo -e "${dim}No conflicts.${reset}"
fi
echo ""

# Stow
stow common
echo -e "Stowed ${cyan}common${reset}"

if $has_custom; then
  stow "$machine"
  echo -e "Stowed ${purple}${machine}${reset}"
fi

echo ""
echo -e "${green}Done.${reset} ${dim}Open a new terminal to verify.${reset}"
