#!/usr/bin/env bash
# Build firmware for the keycapsss 3w6_2040 (RP2040, Pimoroni trackball) on this branch.
#
# Usage:
#   ./build_3w6.sh                # build the 'vial' keymap
#   ./build_3w6.sh default        # build another keymap from keyboards/keycapsss/3w6_2040/keymaps/
#   ./build_3w6.sh vial clean     # clean first, then build
#
# Output: dist/3w6_2040_<keymap>_<branch>_<date>.uf2
set -euo pipefail

KEYMAP="${1:-vial}"
CLEAN="${2:-}"

KEYBOARD="keycapsss/3w6_2040"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST_DIR="$REPO_ROOT/dist"
BRANCH="$(git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD)"

# --- toolchain: arm-none-eabi-gcc (system PATH first, then ~/tools) ----------
if ! command -v arm-none-eabi-gcc >/dev/null 2>&1; then
    LOCAL_TC="$(find "$HOME/tools" -maxdepth 3 -name arm-none-eabi-gcc -type f 2>/dev/null | head -1 || true)"
    if [[ -n "$LOCAL_TC" ]]; then
        export PATH="$(dirname "$LOCAL_TC"):$PATH"
    else
        echo "ERROR: arm-none-eabi-gcc not found." >&2
        echo "Install gcc-arm-none-eabi or extract an ARM GNU toolchain under ~/tools." >&2
        exit 1
    fi
fi
echo "Using GCC: $(arm-none-eabi-gcc --version | head -1)"

# --- python: venv with qmk CLI + repo requirements, else system -------------
QMK_BIN="qmk"
if ! command -v qmk >/dev/null 2>&1; then
    if [[ -x "$HOME/.venvs/qmk/bin/qmk" ]]; then
        export PATH="$HOME/.venvs/qmk/bin:$PATH"
    else
        echo "ERROR: qmk CLI not found. Run: python3 -m venv ~/.venvs/qmk && ~/.venvs/qmk/bin/pip install qmk -r requirements.txt" >&2
        exit 1
    fi
fi
echo "Using qmk: $(qmk --version 2>/dev/null)"

# --- submodules needed for RP2040 builds -------------------------------------
for sm in lib/pico-sdk lib/printf lib/chibios lib/chibios-contrib; do
    if [[ ! -f "$REPO_ROOT/$sm/README.md" && ! -f "$REPO_ROOT/$sm/readme.md" && ! -f "$REPO_ROOT/$sm/README" ]]; then
        echo "Initializing submodule $sm (large download, first run only)..."
        git -C "$REPO_ROOT" submodule update --init "$sm"
    fi
done

# Shared folders (vboxsf) often trip git's ownership check; without this,
# `git describe --dirty` in submodules prints a fatal error into make's
# output and the build dies with "multiple target patterns".
git config --global --add safe.directory "$REPO_ROOT" >/dev/null 2>&1 || true
find "$REPO_ROOT" -name .git -not -path "$REPO_ROOT/.git*" 2>/dev/null | sed "s|/.git$||" | sort -u | while read -r d; do
    git config --global --add safe.directory "$d" >/dev/null 2>&1 || true
done

cd "$REPO_ROOT"
[[ "$CLEAN" == "clean" ]] && make clean

echo "Building ${KEYBOARD}:${KEYMAP} on branch '${BRANCH}'..."
# -Wno-error=array-bounds: GCC 12+ false positive in pico-sdk's rom_hword_as_ptr macro
make "$KEYBOARD:$KEYMAP" EXTRAFLAGS="-Wno-error=array-bounds"

# --- collect the uf2 ---------------------------------------------------------
SRC_UF2="$(find .build -name '*.uf2' | head -1)"
if [[ -z "$SRC_UF2" ]]; then
    echo "ERROR: build finished but no .uf2 was found in .build/" >&2
    exit 1
fi
mkdir -p "$DIST_DIR"
OUT_UF2="$DIST_DIR/3w6_2040_${KEYMAP}_${BRANCH}_$(date +%Y%m%d).uf2"
cp "$SRC_UF2" "$OUT_UF2"

echo
echo "Done. Firmware: $OUT_UF2"
echo "Flash: hold BOOTSEL on the keyboard's RP2040 while plugging it in, then copy the .uf2 to the BOOTDRIVE volume."
