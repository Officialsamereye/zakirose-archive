#!/bin/bash
# Zaki Rose Archive installer / updater for macOS.
# Run again any time to update. Your settings and reports are kept.
set -euo pipefail
REPO="Officialsamereye/zakirose-archive"
BRANCH="main"
APP="Zaki Rose Archive.app"
SUP="$HOME/Library/Application Support/Zaki Rose Archive"

say() { printf '\033[1;38;2;216;103;63m›\033[0m %s\n' "$1"; }
[ "$(uname)" = "Darwin" ] || { echo "This installer is for macOS."; exit 1; }

say "Installing Zaki Rose Archive"

# 1. rclone (the transfer engine)
if [ -x /usr/local/bin/rclone ] || [ -x /opt/homebrew/bin/rclone ]; then
  say "rclone found"
else
  say "Installing rclone (macOS will ask for your password)"
  sudo -v
  curl -fsSL https://rclone.org/install.sh | sudo bash
fi

# 2. stop a running engine so files can be replaced
if [ -s "$SUP/.engine" ]; then
  curl -s -m 3 -u "zr:$(cat "$SUP/.engine")" -X POST http://127.0.0.1:5572/core/quit >/dev/null 2>&1 && say "Stopped the running engine" || true
  sleep 1
fi
launchctl bootout "gui/$(id -u)/com.zakirose.archive.engine" >/dev/null 2>&1 || true

# 3. download and install the app
DEST="/Applications"; [ -w "$DEST" ] || { DEST="$HOME/Applications"; mkdir -p "$DEST"; }
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
say "Downloading the latest version"
curl -fsSL "https://codeload.github.com/$REPO/tar.gz/refs/heads/$BRANCH" | tar -xz -C "$TMP"
SRC="$(find "$TMP" -maxdepth 2 -type d -name "$APP" | head -n 1)"
[ -n "$SRC" ] || { echo "Download didn't contain the app."; exit 1; }
rm -rf "$DEST/$APP"
cp -R "$SRC" "$DEST/"
chmod +x "$DEST/$APP/Contents/MacOS/ZakiRoseArchive"
xattr -dr com.apple.quarantine "$DEST/$APP" 2>/dev/null || true
VER="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$DEST/$APP/Contents/Info.plist" 2>/dev/null || echo "")"
say "Installed version $VER to $DEST"

# 4. open it
open "$DEST/$APP"
say "Done. Zaki Rose Archive is opening."
echo
echo "  One-time step: give the transfer engine access to LucidLink."
echo "  System Settings → Privacy & Security → Full Disk Access → +"
echo "  press ⌘⇧G, paste the path below, click Open, switch it on:"
echo
echo "      $(command -v rclone || echo /usr/local/bin/rclone)"
echo
