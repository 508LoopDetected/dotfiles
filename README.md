# dotfiles

My configs/dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/), plus some additional logic to support parent/child inheritance + config backups. Surely the ideal "Not Quite Chezmoi" package already exists out there, but it seemed just as quick to Roll My Own™ with only what I needed.

## Structure

- **`common/`** — Shared configs (nvim, ghostty, starship, zshrc-common). Stow on every machine.
- **`<machine>/`** — Machine-specific configs (e.g. zshrc with host-specific settings). One per machine.
- **`resources/`** — Fonts, wallpapers, images, scripts. Not a stow package.

## Fresh install

```sh
git clone <repo-url> ~/dotfiles
cd ~/dotfiles
./install.sh
```

The installer auto-detects your hostname and matches it to an existing package. If no package exists, it offers to create one. For each conflicting file, you choose to **backup** (.bak) or **overwrite**.

Safe to re-run — existing symlinks are skipped and stow is idempotent. If switching to a different machine package, the old one is unstowed automatically.

## Manual stow

```sh
cd ~/dotfiles
stow common          # shared configs
stow <machine>       # machine-specific
```

Only needed when adding a new file to an existing package. Edits to already-stowed files are live immediately via symlinks.

## Adding a new machine

Just run `./install.sh` on the new machine — it will offer to create a package for the hostname. Add a `.zshrc` that sources `~/.zshrc-common` with any machine-specific config, then re-run `./install.sh`.

## Uninstall

```sh
cd ~/dotfiles
./uninstall.sh
```

Removes all symlinks and restores standalone config files. For each file:
- If a `.bak` exists (from install), you can **restore** the backup or **copy** from the repo
- If no backup exists, you can **copy** from the repo or **skip** (leave nothing)

After uninstalling, configs are regular files again — no longer linked to the repo.
