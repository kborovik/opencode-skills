#!/usr/bin/env bash
# test-install.sh — smoke test for install.sh (repo root).
#
# Validates:
#   I.install-sh — deploy shape (clone dir + three symlinks), idempotent re-run,
#                  pre-existing non-symlink at target left in place
#   V26          — REPO env / positional arg can override the default repo slug
#                  (here exercised via a local-path REPO)
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_SH="${HERE}/../install.sh"

fail() { printf 'not ok %s\n' "$*" >&2; exit 1; }
ok()   { printf 'ok  %s\n' "$*"; }

SRC_REPO="$(mktemp -dt openskills-src.XXXXXX)"
HOME1="$(mktemp -dt openskills-home1.XXXXXX)"
HOME2="$(mktemp -dt openskills-home2.XXXXXX)"
trap 'rm -rf "${SRC_REPO}" "${HOME1}" "${HOME2}"' EXIT

mkdir -p "${SRC_REPO}/skills/test-skill" "${SRC_REPO}/commands" "${SRC_REPO}/scripts"
printf 'skill\n' > "${SRC_REPO}/skills/test-skill/SKILL.md"
printf 'cmd\n'   > "${SRC_REPO}/commands/sdd-test.md"
printf 'audit\n' > "${SRC_REPO}/scripts/check-mechanical.py"
git -C "${SRC_REPO}" -c init.defaultBranch=main init -q
git -C "${SRC_REPO}" -c user.email=t@t -c user.name=t add -A
git -C "${SRC_REPO}" -c user.email=t@t -c user.name=t commit -q -m init

# V26: REPO env points at the local repo (parametric).
HOME="${HOME1}" REPO="${SRC_REPO}" REF="main" "${INSTALL_SH}"

REPO_BASENAME="$(basename "${SRC_REPO}")"
CLONE_DIR="${HOME1}/.local/share/opencode-skills/${REPO_BASENAME}"

[ -d "${CLONE_DIR}/.git" ]                                     || fail "clone dir not created"
[ -L "${HOME1}/.config/opencode/skills" ]                      || fail "skills symlink absent"
[ -L "${HOME1}/.config/opencode/commands" ]                    || fail "commands symlink absent"
[ -L "${HOME1}/.opencode/scripts/check-mechanical.py" ]        || fail "audit script symlink absent"
[ "$(readlink "${HOME1}/.config/opencode/skills")" = "${CLONE_DIR}/skills" ] \
  || fail "skills symlink wrong target"
[ -f "${HOME1}/.config/opencode/skills/test-skill/SKILL.md" ]  || fail "skills payload not reachable"
[ "$(cat "${HOME1}/.config/opencode/skills/test-skill/SKILL.md")" = "skill" ] \
  || fail "skills payload content mismatch"
ok "deploy shape"

# I.install-sh: idempotent re-run.
HOME="${HOME1}" REPO="${SRC_REPO}" REF="main" "${INSTALL_SH}"
[ -L "${HOME1}/.config/opencode/skills" ]                      || fail "skills symlink clobbered on rerun"
[ "$(readlink "${HOME1}/.config/opencode/skills")" = "${CLONE_DIR}/skills" ] \
  || fail "skills symlink target changed on rerun"
ok "idempotent rerun"

# I.install-sh: pre-existing non-symlink at target must not be clobbered.
mkdir -p "${HOME2}/.config/opencode"
printf 'user-data\n' > "${HOME2}/.config/opencode/skills"
HOME="${HOME2}" REPO="${SRC_REPO}" REF="main" "${INSTALL_SH}"
[ -f "${HOME2}/.config/opencode/skills" ]                       || fail "pre-existing skills entry removed"
[ "$(cat "${HOME2}/.config/opencode/skills")" = "user-data" ]   || fail "pre-existing skills content clobbered"
ok "pre-existing target preserved"

echo "all ok"
