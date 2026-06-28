# dotfiles

My configs/dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/), plus some additional logic to support parent/child inheritance and config backups. Surely the ideal "Not Quite Chezmoi" package already exists out there, but it seemed just as quick to Roll My Own™ with only what I needed.

## Structure

- **`common/`**: Shared configs (nvim, ghostty, starship, zshrc-common). Stow on every machine.
- **`profiles/<hostname>/`**: Machine-specific configs (e.g. zshrc with host-specific settings). One per machine.
- **`resources/`**: Fonts, wallpapers, images, scripts. Not a stow package.

## Install

```sh
git clone <repo-url> ~/dotfiles
cd ~/dotfiles
./install.sh
```

The installer auto-detects your hostname and matches it to an existing package. For each conflicting file, you choose to **backup** (.bak) or **overwrite**.

Safe to re-run. Existing symlinks are skipped and stow is idempotent. If switching to a different machine package, the old one is unstowed automatically.

### First time on a new machine

If no package exists for the current hostname, `install.sh` offers to create one and scaffolds a starter `profiles/<hostname>/.zshrc` that sources `~/.zshrc-common`. Edit it afterward to add any machine-specific config.

## Manual stow

```sh
cd ~/dotfiles
stow common                                    # shared configs
stow -d profiles -t "$HOME" <hostname>         # machine-specific
```

Only needed when adding a new file to an existing package. Edits to already-stowed files are live immediately via symlinks.

## Uninstall

```sh
cd ~/dotfiles
./uninstall.sh
```

Removes all symlinks and restores standalone config files. For each file:
- If a `.bak` exists (from install), you can **restore** the backup or **copy** from the repo.
- If no backup exists, you can **copy** from the repo or **skip** (leave nothing).

After uninstalling, configs are regular files again, no longer linked to the repo.
