#!/usr/bin/env bash
# Symlinks everything under ./home/ into $HOME, preserving structure.
# Backs up existing non-symlink files to ~/.dotfiles-backup/<timestamp>/
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$DOTFILES_DIR/home"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

if [[ ! -d "$SRC_DIR" ]]; then
    echo "error: $SRC_DIR does not exist" >&2
    exit 1
fi

DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

link_file() {
    local src="$1"
    local rel="${src#$SRC_DIR/}"
    local dest="$HOME/$rel"
    local dest_dir
    dest_dir="$(dirname "$dest")"

    # Already linked correctly? Skip.
    if [[ -L "$dest" ]] && [[ "$(readlink "$dest")" == "$src" ]]; then
        echo "ok    $rel"
        return
    fi

    if (( DRY_RUN )); then
        echo "would  $rel -> $src"
        return
    fi

    mkdir -p "$dest_dir"

    # Back up existing file/dir/wrong symlink
    if [[ -e "$dest" ]] || [[ -L "$dest" ]]; then
        mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
        mv "$dest" "$BACKUP_DIR/$rel"
        echo "backup $rel -> $BACKUP_DIR/$rel"
    fi

    ln -s "$src" "$dest"
    echo "link   $rel -> $src"
}

# Walk every regular file under home/.
while IFS= read -r -d '' file; do
    link_file "$file"
done < <(find "$SRC_DIR" -type f -print0)

echo
if (( DRY_RUN )); then
    echo "dry run complete. re-run without --dry-run to apply."
else
    echo "done. backups (if any) are in $BACKUP_DIR"
fi

