#!/usr/bin/env bash
# install.sh — global deploy for the opencode-skills pack.
#
# - clones <REPO> into ~/.local/share/opencode-skills/<repo-name>
#   (skipped if the clone dir already holds a git repo)
# - symlinks <clone>/skills, <clone>/commands, and
#   <clone>/scripts/check-mechanical.py into the per-consumer target dirs
#   (~/.config/opencode/, ~/.opencode/scripts/)
# - idempotent: re-running is safe; existing non-matching symlinks or real
#   entries at the target are reported and left in place (operator must
#   clean up before the symlink will take effect)
# - bootstrap: `curl -fsSL .../scripts/install.sh | sh`
#   REPO env var (or first positional arg) overrides the default
#   owner/repo; REF overrides the branch/ref
#
# V26: repo-specific slugs are derived from $REPO at runtime, never hardcoded.
set -euo pipefail

DEFAULT_REPO="kborovik/opencode-skills"
: "${REPO:=${1:-${DEFAULT_REPO}}}"
: "${REF:=main}"

REPO_NAME="${REPO##*/}"
CLONE_DIR="${HOME}/.local/share/opencode-skills/${REPO_NAME}"

# Tolerate local-path REPO (used by tests); otherwise treat as owner/repo slug.
if [ -d "${REPO}" ] && [ -d "${REPO}/.git" ]; then
  REPO_URL="${REPO}"
else
  REPO_URL="https://github.com/${REPO}.git"
fi

mkdir -p "$(dirname "${CLONE_DIR}")"

if [ -d "${CLONE_DIR}/.git" ]; then
  git -C "${CLONE_DIR}" pull --ff-only
else
  git clone --depth=1 --branch "${REF}" "${REPO_URL}" "${CLONE_DIR}"
fi

link() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "${dst}")"
  if [ -L "${dst}" ]; then
    local target
    target="$(readlink "${dst}")"
    if [ "${target}" = "${src}" ]; then
      return 0
    fi
    printf 'install: skip %s -> %s (existing symlink to %s)\n' "${dst}" "${src}" "${target}" >&2
    return 0
  fi
  if [ -e "${dst}" ]; then
    printf 'install: skip %s -> %s (existing non-symlink)\n' "${dst}" "${src}" >&2
    return 0
  fi
  ln -s "${src}" "${dst}"
}

link "${CLONE_DIR}/skills"                      "${HOME}/.config/opencode/skills"
link "${CLONE_DIR}/commands"                    "${HOME}/.config/opencode/commands"
link "${CLONE_DIR}/scripts/check-mechanical.py" "${HOME}/.opencode/scripts/check-mechanical.py"
