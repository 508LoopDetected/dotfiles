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

# Track actions for summary
summary_backed=()
summary_overwritten=()
summary_linked=()
summary_written=()

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
    summary_backed+=("~/$f -> ~/$f.bak")
  else
    rm -rf "$HOME/$f"
    echo -e "  ${red}removed${reset}   ~/$f"
    summary_overwritten+=("~/$f")
  fi
done 3<<< "$targets"

if [ "$conflicts" -eq 0 ]; then
  echo -e "${dim}No conflicts.${reset}"
fi
echo ""

# Stow
stow common
echo -e "Stowed ${cyan}common${reset}"
while IFS= read -r f; do
  summary_linked+=("~/$f -> dotfiles/common/$f")
done < <(collect_targets common)

if $has_custom; then
  # --override lets machine files take over links already placed by common
  stow --override='.*' "$machine"
  echo -e "Stowed ${purple}${machine}${reset}"
  while IFS= read -r f; do
    summary_linked+=("~/$f -> dotfiles/$machine/$f")
  done < <(collect_targets "$machine")
fi

# Git identity setup
echo ""
echo -e "${bold}Git identity${reset}"
echo -e "  ${green}p${reset})ersonal  ${green}w${reset})ork  ${dim}s${reset})kip"
while true; do
  read -rp "  > " git_choice </dev/tty
  case "$git_choice" in
    p|P) git_mode="personal"; break ;;
    w|W) git_mode="work"; break ;;
    s|S) git_mode="skip"; break ;;
    *) echo -e "  ${dim}p / w / s${reset}" ;;
  esac
done

if [ "$git_mode" != "skip" ]; then
  echo ""
  read -rp "$(echo -e "Git name: ")" git_name </dev/tty

  if [ "$git_mode" = "personal" ]; then
    read -rp "$(echo -e "Personal email: ")" git_email </dev/tty

    cat > "$HOME/.gitconfig" <<EOF
[user]
	name = $git_name
	email = $git_email
EOF
    summary_written+=("~/.gitconfig (personal)")

    read -rp "$(echo -e "Taking work home? Directory ${dim}(e.g. ~/Sites/work — blank to skip)${reset}: ")" work_dir </dev/tty
    if [ -n "$work_dir" ]; then
      read -rp "$(echo -e "Work email: ")" work_email </dev/tty
      work_name=$(basename "$work_dir")
      work_config=".gitconfig-${work_name}"

      [[ "$work_dir" != */ ]] && work_dir="${work_dir}/"

      cat >> "$HOME/.gitconfig" <<EOF
[includeIf "gitdir:${work_dir}"]
	path = ~/${work_config}
EOF

      cat > "$HOME/${work_config}" <<EOF
[user]
	email = $work_email
EOF
      echo -e "Wrote ${cyan}~/${work_config}${reset}"
      summary_written+=("~/${work_config} (work override for ${work_dir})")
    fi

    echo -e "Wrote ${cyan}~/.gitconfig${reset}"

  else
    # Work machine — single identity
    read -rp "$(echo -e "Work email: ")" git_email </dev/tty

    cat > "$HOME/.gitconfig" <<EOF
[user]
	name = $git_name
	email = $git_email
EOF
    echo -e "Wrote ${cyan}~/.gitconfig${reset}"
    summary_written+=("~/.gitconfig (work)")
  fi
else
  echo -e "${dim}Skipped git identity.${reset}"
fi

# Summary
echo ""
echo -e "${bold}Summary${reset}"

if [ ${#summary_overwritten[@]} -gt 0 ]; then
  echo -e "  ${red}Overwritten:${reset}"
  for f in "${summary_overwritten[@]}"; do echo -e "    ${dim}${f}${reset}"; done
fi

if [ ${#summary_backed[@]} -gt 0 ]; then
  echo -e "  ${blue}Backed up:${reset}"
  for f in "${summary_backed[@]}"; do echo -e "    ${dim}${f}${reset}"; done
fi

if [ ${#summary_linked[@]} -gt 0 ]; then
  echo -e "  ${green}Linked:${reset}"
  for f in "${summary_linked[@]}"; do echo -e "    ${dim}${f}${reset}"; done
fi

if [ ${#summary_written[@]} -gt 0 ]; then
  echo -e "  ${cyan}Written:${reset}"
  for f in "${summary_written[@]}"; do echo -e "    ${dim}${f}${reset}"; done
fi

echo ""
echo -e "${green}Done.${reset} ${dim}Open a new terminal to verify.${reset}"
