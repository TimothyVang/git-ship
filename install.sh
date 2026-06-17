#!/usr/bin/env bash
# install.sh — one-line installer for git-ship.
#
#   curl -fsSL https://raw.githubusercontent.com/TimothyVang/git-ship/main/install.sh | bash
#
# Downloads the single `git-ship` script onto your PATH and makes it executable,
# so you can run it as `git-ship ...` or as the git subcommand `git ship ...`.
# No dependencies beyond `git`, `curl` (or `wget`), and a POSIX shell.
#
# Options (pass after `| bash -s --`):
#   --dir=PATH   install directory (default: ~/.local/bin)
#   --ref=REF    branch/tag to fetch the script from (default: main)
#   -h|--help    show this help
#
# Env: GIT_SHIP_DIR overrides the install directory.

set -euo pipefail

REPO="TimothyVang/git-ship"
REF="main"
DIR="${GIT_SHIP_DIR:-$HOME/.local/bin}"

c_grn=$'\033[0;32m'; c_yel=$'\033[0;33m'; c_blu=$'\033[0;34m'; c_red=$'\033[0;31m'; c_off=$'\033[0m'
info() { echo "${c_blu}[git-ship]${c_off} $*"; }
ok()   { echo "${c_grn}[git-ship]${c_off} $*"; }
warn() { echo "${c_yel}[git-ship]${c_off} $*"; }
die()  { echo "${c_red}[git-ship]${c_off} $*" >&2; exit 1; }

for arg in "$@"; do
  case "${arg}" in
    --dir=*) DIR="${arg#*=}" ;;
    --ref=*) REF="${arg#*=}" ;;
    -h|--help)
      echo "Usage: curl -fsSL .../install.sh | bash [-s -- --dir=PATH --ref=REF]"
      exit 0 ;;
    *) die "unknown argument '${arg}' (try --help)" ;;
  esac
done

SRC="https://raw.githubusercontent.com/${REPO}/${REF}/git-ship"
DEST="${DIR%/}/git-ship"

# git-ship drives git; warn (don't fail) if it's missing.
command -v git >/dev/null 2>&1 || warn "git is not on PATH — git-ship needs it at run time."

mkdir -p "${DIR}"

info "downloading git-ship (${REF}) -> ${DEST}"
if command -v curl >/dev/null 2>&1; then
  curl -fsSL "${SRC}" -o "${DEST}" || die "download failed from ${SRC}"
elif command -v wget >/dev/null 2>&1; then
  wget -qO "${DEST}" "${SRC}" || die "download failed from ${SRC}"
else
  die "need curl or wget to download git-ship."
fi

chmod +x "${DEST}"

# Sanity check: the script must at least parse and respond to --help.
if ! bash "${DEST}" --help >/dev/null 2>&1; then
  die "downloaded git-ship did not run cleanly — aborting."
fi

ok "installed git-ship -> ${DEST}"

# PATH guidance.
case ":${PATH}:" in
  *":${DIR%/}:"*) ok "'${DIR%/}' is already on your PATH." ;;
  *)
    warn "'${DIR%/}' is NOT on your PATH. Add this to your shell profile:"
    echo "    export PATH=\"${DIR%/}:\$PATH\""
    ;;
esac

echo
ok "ready. Try it:"
echo "    git-ship --help            # all options  (note: 'git ship --help' is hijacked by git's man pages; use the hyphen, or 'git ship -h')"
echo "    git ship --tag v1.0.0      # push current branch + cut a release"
