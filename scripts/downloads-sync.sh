#!/bin/bash
set -euo pipefail

# Downloads Sync & Organize
# Mirrors ~/Downloads to external drive, then sorts files by type.
# Designed to run weekly via launchd (every Friday).

# --- Config ---
EXTERNAL_VOL_NAME="${EXTERNAL_VOL_NAME:-WorkFlow}"
EXTERNAL_ROOT="/Volumes/$EXTERNAL_VOL_NAME"
DEST="$EXTERNAL_ROOT/Downloads"
SRC="$HOME/Downloads"
LOG_PREFIX="[downloads-sync]"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $LOG_PREFIX $1"; }
notify() {
    local title="$1" subtitle="$2" message="$3" sound="${4:-Glass}"
    osascript -e "display notification \"$message\" with title \"$title\" subtitle \"$subtitle\" sound name \"$sound\""
}

# --- Preflight ---
if [ ! -d "$EXTERNAL_ROOT" ]; then
    log "ERROR: External volume not found: $EXTERNAL_ROOT — skipping sync."
    notify "Downloads Sync" "Error" "External drive not found — sync skipped" "Basso"
    exit 1
fi

if [ ! -d "$SRC" ]; then
    log "ERROR: Source not found: $SRC"
    notify "Downloads Sync" "Error" "~/Downloads not found" "Basso"
    exit 1
fi

mkdir -p "$DEST"

# Category folder names (excluded from rsync --delete so organized files persist)
CATEGORIES="Images Documents Videos Audio Archives Code Installers Other 3D_Printing Game_Assets Game_ROMs Hardware"

# Build rsync exclude flags for category folders
RSYNC_EXCLUDES="--exclude=.DS_Store"
for cat in $CATEGORIES; do
    RSYNC_EXCLUDES="$RSYNC_EXCLUDES --exclude=$cat/"
done

# --- Step 1: Rsync (additive sync, only deletes non-category files that were removed from source) ---
log "Syncing $SRC → $DEST ..."
eval rsync -a --delete $RSYNC_EXCLUDES "\"$SRC\"/" "\"$DEST\"/"
log "Sync complete."

# --- Step 2: Sort files by type ---
log "Organizing files by type..."

# Extension → category lookup (macOS /bin/bash is v3.x, no associative arrays)
get_category() {
    local ext="$1"
    case "$ext" in
        jpg|jpeg|png|gif|svg|webp|ico|bmp|tiff|heic) echo "Images" ;;
        pdf|doc|docx|xls|xlsx|ppt|pptx|txt|rtf|csv|pages|numbers|keynote) echo "Documents" ;;
        mp4|mov|avi|mkv|webm|m4v) echo "Videos" ;;
        mp3|wav|aac|flac|m4a|ogg) echo "Audio" ;;
        zip|tar|gz|rar|7z|dmg|iso) echo "Archives" ;;
        js|ts|jsx|tsx|py|sh|json|html|css|scss|md|yaml|yml|toml) echo "Code" ;;
        stl|3mf|obj|step|gcode|fcstd) echo "3D_Printing" ;;
        glb|gltf|fbx|blend|riv|aseprite|ase) echo "Game_Assets" ;;
        gba|gbc|nds|nes|sfc|n64|deltaskin) echo "Game_ROMs" ;;
        kicad_mod|kicad_sym|kicad_pcb|kicad_sch|kicad_pro) echo "Hardware" ;;
        pkg|app) echo "Installers" ;;
        *) echo "Other" ;;
    esac
}

moved=0

for file in "$DEST"/*; do
    [ ! -f "$file" ] && continue

    filename="$(basename "$file")"

    # Skip hidden files
    case "$filename" in .*) continue ;; esac

    # Get extension (lowercase)
    ext="${filename##*.}"
    ext="$(echo "$ext" | tr '[:upper:]' '[:lower:]')"

    # If no extension or same as filename (no dot), use Other
    if [ "$ext" = "$filename" ]; then
        category="Other"
    else
        category="$(get_category "$ext")"
    fi

    # Move file into category folder
    mkdir -p "$DEST/$category"
    if [ -f "$DEST/$category/$filename" ]; then
        # Avoid overwriting: append timestamp
        base="${filename%.*}"
        mv "$file" "$DEST/$category/${base}_$(date +%Y%m%d-%H%M%S).$ext"
    else
        mv "$file" "$DEST/$category/"
    fi
    moved=$((moved + 1))
done

log "Organized $moved file(s) into category folders."
notify "Downloads Sync" "Complete" "Synced & organized $moved file(s) to $EXTERNAL_VOL_NAME" "Glass"
log "Done."
