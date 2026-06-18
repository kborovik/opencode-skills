#!/usr/bin/env bash
# test-install.sh — smoke test for install.sh (repo root).
#
# Validates:
#   I.install-sh — deploy shape (clone dir + per-file symlinks for each entry
#                  under <clone>/skills/, <clone>/commands/, <clone>/scripts/),
#                  idempotent re-run, pre-existing non-symlink at target left
#                  in place
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
printf 'test\n'  > "${SRC_REPO}/scripts/test-install.sh"
git -C "${SRC_REPO}" -c init.defaultBranch=main init -q
git -C "${SRC_REPO}" -c user.email=t@t -c user.name=t add -A
git -C "${SRC_REPO}" -c user.email=t@t -c user.name=t commit -q -m init

# V26: REPO env points at the local repo (parametric).
HOME="${HOME1}" REPO="${SRC_REPO}" REF="main" "${INSTALL_SH}"

REPO_BASENAME="$(basename "${SRC_REPO}")"
CLONE_DIR="${HOME1}/.local/share/opencode-skills/${REPO_BASENAME}"

# I.install-sh: clone dir created.
[ -d "${CLONE_DIR}/.git" ]                                                       || fail "clone dir not created"
ok "clone dir"

# I.install-sh: per-file symlinks under each target dir.
SKILL_LINK="${HOME1}/.config/opencode/skills/test-skill"
CMD_LINK="${HOME1}/.config/opencode/commands/sdd-test.md"
SCRIPT_LINK="${HOME1}/.opencode/scripts/check-mechanical.py"
TEST_LINK="${HOME1}/.opencode/scripts/test-install.sh"

[ -L "${SKILL_LINK}" ]                                                           || fail "skills per-file symlink absent"
[ -L "${CMD_LINK}" ]                                                             || fail "commands per-file symlink absent"
[ -L "${SCRIPT_LINK}" ]                                                          || fail "scripts per-file symlink absent (check-mechanical.py)"
[ -L "${TEST_LINK}" ]                                                            || fail "scripts per-file symlink absent (test-install.sh)"
[ "$(readlink "${SKILL_LINK}")" = "${CLONE_DIR}/skills/test-skill" ]             || fail "skills symlink wrong target"
[ "$(readlink "${CMD_LINK}")" = "${CLONE_DIR}/commands/sdd-test.md" ]            || fail "commands symlink wrong target"
[ "$(readlink "${SCRIPT_LINK}")" = "${CLONE_DIR}/scripts/check-mechanical.py" ]  || fail "scripts symlink wrong target (check-mechanical.py)"
[ "$(readlink "${TEST_LINK}")" = "${CLONE_DIR}/scripts/test-install.sh" ]        || fail "scripts symlink wrong target (test-install.sh)"
ok "per-file symlinks"

# I.install-sh: payload reachable through per-file symlink.
[ -f "${SKILL_LINK}/SKILL.md" ]                                                  || fail "skills payload not reachable through per-file symlink"
[ "$(cat "${SKILL_LINK}/SKILL.md")" = "skill" ]                                  || fail "skills payload content mismatch"
[ "$(cat "${CMD_LINK}")" = "cmd" ]                                               || fail "commands payload content mismatch"
[ "$(cat "${SCRIPT_LINK}")" = "audit" ]                                          || fail "scripts payload content mismatch (check-mechanical.py)"
[ "$(cat "${TEST_LINK}")" = "test" ]                                             || fail "scripts payload content mismatch (test-install.sh)"
ok "payload reachable"

# I.install-sh: idempotent re-run.
HOME="${HOME1}" REPO="${SRC_REPO}" REF="main" "${INSTALL_SH}"
[ -L "${SKILL_LINK}" ]                                                           || fail "skills per-file symlink clobbered on rerun"
[ -L "${CMD_LINK}" ]                                                             || fail "commands per-file symlink clobbered on rerun"
[ -L "${SCRIPT_LINK}" ]                                                          || fail "scripts per-file symlink clobbered on rerun (check-mechanical.py)"
[ "$(readlink "${SKILL_LINK}")" = "${CLONE_DIR}/skills/test-skill" ]             || fail "skills symlink target changed on rerun"
[ "$(readlink "${CMD_LINK}")" = "${CLONE_DIR}/commands/sdd-test.md" ]            || fail "commands symlink target changed on rerun"
[ "$(readlink "${SCRIPT_LINK}")" = "${CLONE_DIR}/scripts/check-mechanical.py" ]  || fail "scripts symlink target changed on rerun"
ok "idempotent rerun"

# I.install-sh: pre-existing non-symlink at per-file target must not be clobbered.
mkdir -p "${HOME2}/.config/opencode/skills/test-skill"
printf 'user-data\n' > "${HOME2}/.config/opencode/skills/test-skill/SKILL.md"
HOME="${HOME2}" REPO="${SRC_REPO}" REF="main" "${INSTALL_SH}"
[ -f "${HOME2}/.config/opencode/skills/test-skill/SKILL.md" ]                    || fail "pre-existing per-file entry removed"
[ "$(cat "${HOME2}/.config/opencode/skills/test-skill/SKILL.md")" = "user-data" ] || fail "pre-existing per-file content clobbered"
ok "pre-existing per-file target preserved"

echo "all ok"