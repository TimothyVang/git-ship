#!/usr/bin/env bash
# install.sh — one-line installer for git-ship.
#
#   curl -fsSL https://raw.githubusercontent.com/TimothyVang/git-ship/main/install.sh | bash
#
# Downloads the single `git-ship` script, puts it on your PATH, and (by default)
# adds that location to your shell profile so `git ship ...` / `git-ship ...`
# work in new terminals. Built to work even if you've never set up a CLI before.
#
# Options (pass after `| bash -s --`):
#   --dir=PATH         install directory (default: a writable dir already on PATH,
#                      else ~/.local/bin)
#   --ref=REF          branch/tag to fetch the script from (default: main)
#   --no-modify-path   don't touch your shell profile (just print PATH guidance)
#   -h|--help          show this help
#
# Env: GIT_SHIP_DIR overrides the install directory.

set -euo pipefail

REPO="TimothyVang/git-ship"
REF="main"
DIR=""
MODIFY_PATH=1

c_grn=$'\033[0;32m'; c_yel=$'\033[0;33m'; c_blu=$'\033[0;34m'; c_red=$'\033[0;31m'; c_off=$'\033[0m'
info() { echo "${c_blu}[git-ship]${c_off} $*"; }
ok()   { echo "${c_grn}[git-ship]${c_off} $*"; }
warn() { echo "${c_yel}[git-ship]${c_off} $*"; }
die()  { echo "${c_red}[git-ship]${c_off} $*" >&2; exit 1; }

for arg in "$@"; do
  case "${arg}" in
    --dir=*)          DIR="${arg#*=}" ;;
    --ref=*)          REF="${arg#*=}" ;;
    --no-modify-path) MODIFY_PATH=0 ;;
    -h|--help)
      echo "Usage: curl -fsSL .../install.sh | bash [-s -- --dir=PATH --ref=REF --no-modify-path]"
      exit 0 ;;
    *) die "unknown argument '${arg}' (try --help)" ;;
  esac
done

on_path() { case ":${PATH}:" in *":$1:"*) return 0;; *) return 1;; esac; }
# Usable if it exists and is writable, or doesn't exist but its parent is writable.
can_use() { if [ -d "$1" ]; then [ -w "$1" ]; else [ ! -e "$1" ] && [ -w "$(dirname "$1")" ]; fi; }

# Resolve the install dir: explicit choice wins; otherwise prefer a dir that's
# already on PATH and writable (so no profile edit is needed), else ~/.local/bin.
[ -z "$DIR" ] && DIR="${GIT_SHIP_DIR:-}"
if [ -z "$DIR" ]; then
  DIR="$HOME/.local/bin"
  for c in /usr/local/bin "$HOME/.local/bin" "$HOME/bin"; do
    if on_path "$c" && can_use "$c"; then DIR="$c"; break; fi
  done
fi
DIR="${DIR%/}"

SRC="https://raw.githubusercontent.com/${REPO}/${REF}/git-ship"
DEST="${DIR}/git-ship"

command -v git >/dev/null 2>&1 || warn "git is not on PATH — git-ship needs it at run time."

mkdir -p "${DIR}" || die "cannot create install dir ${DIR}"

info "downloading git-ship (${REF}) -> ${DEST}"
if command -v curl >/dev/null 2>&1; then
  curl -fsSL "${SRC}" -o "${DEST}" || die "download failed from ${SRC}"
elif command -v wget >/dev/null 2>&1; then
  wget -qO "${DEST}" "${SRC}" || die "download failed from ${SRC}"
else
  die "need curl or wget to download git-ship."
fi
chmod +x "${DEST}"
bash "${DEST}" --help >/dev/null 2>&1 || die "downloaded git-ship did not run cleanly — aborting."
ok "installed git-ship -> ${DEST}"

# --- put it on PATH ----------------------------------------------------------
add_to_profile() {
  local dir="$1" shellname profile line
  shellname="$(basename "${SHELL:-sh}")"
  case "$shellname" in
    zsh)  profile="$HOME/.zshrc" ;;
    bash) profile="$HOME/.bashrc" ;;
    fish) profile="$HOME/.config/fish/config.fish" ;;
    *)    profile="$HOME/.profile" ;;
  esac
  mkdir -p "$(dirname "$profile")" 2>/dev/null || true
  if [ "$shellname" = fish ]; then line="fish_add_path $dir"; else line="export PATH=\"$dir:\$PATH\""; fi
  if grep -qsF "$dir" "$profile" 2>/dev/null; then
    ok "$profile already puts $dir on PATH"
  elif printf '\n# Added by git-ship installer\n%s\n' "$line" >> "$profile" 2>/dev/null; then
    ok "added $dir to PATH in $profile"
  else
    warn "couldn't edit a profile — add this line to your shell startup file yourself:"
    echo "    $line"
    return
  fi
  warn "open a new terminal, or run:  source $profile"
}

if on_path "${DIR}"; then
  ok "'${DIR}' is on your PATH."
elif [ "$MODIFY_PATH" = 1 ]; then
  add_to_profile "${DIR}"
else
  warn "'${DIR}' is NOT on your PATH. Add this to your shell profile:"
  echo "    export PATH=\"${DIR}:\$PATH\""
fi

# --- release-auth nudge (pushing needs none; releases need gh or a token) ----
if command -v gh >/dev/null 2>&1; then
  if ! gh auth status >/dev/null 2>&1; then
    warn "to cut GitHub releases, log in once:  gh auth login"
  fi
else
  warn "no gh CLI found — pushing works as-is. To cut releases, either:"
  echo "    install gh (https://cli.github.com) then run:  gh auth login"
  echo "    or set a token:  export GH_TOKEN=<your github token>"
fi

echo
ok "ready. Try it:"
echo "    git-ship --help            # all options  ('git ship --help' is hijacked by git's man pages; use the hyphen, or 'git ship -h')"
echo "    git ship --tag v1.0.0      # push current branch + cut a release"
