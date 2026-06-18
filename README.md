# opencode-skills

SDD (spec-driven development) skill pack for [OpenCode](https://opencode.ai) — spec, build, check, condense, design, and friends.

A set of [agent skills](https://opencode.ai/docs/skills/) and slash commands that implement a spec-driven development workflow around a root `SPEC.md`: author spec, build against it, detect drift, condense, design, and reorganize.

## Contents

```
opencode-skills/
├── commands/   6 slash commands (sdd-build, sdd-check, sdd-condense, sdd-design, sdd-reorganize, sdd-spec)
├── scripts/    check-mechanical.py — mechanical audit core used by the `check` skill
└── skills/     13 agent skills (one folder per skill, each with SKILL.md)
```

### Skills

| skill | role |
|---|---|
| `spec` | Sole semantic author of SPEC.md — create, amend, fold designs, backprop bugs. |
| `build` | Plan-then-execute implementation vs SPEC.md. |
| `check` | Read-only drift detector. Diffs SPEC.md vs code, reports violations by severity. |
| `condense` | SPEC.md token-budget sweep. |
| `design` | Propose-then-critique structural design loop → `designs/<slug>.md`. |
| `reorganize` | SPEC.md §V cluster + renumber + cite-DAG sweep. |
| `explain` | Telegraph → prose. Expand one SPEC.md citation into plain English. |
| `commit` | Commit staged changes with a Conventional Commits message. |
| `backprop` | Internal — bug → spec protocol. |
| `socratic` | Internal — single-question intent-sharpening gate. |
| `steno` | Internal — terse-prose register for non-author reviewers. |
| `telegraph` | Internal — telegraph encoding for SPEC.md writes. |
| `monitor` | Internal — skill-deviation capture. |

## Install

This repo ships skills, commands, and the audit script only. Global opencode config (e.g. `opencode.jsonc`, `default_agent`) is the consumer's responsibility and intentionally not included.

### Global install

```sh
# skills
cp -R skills/* ~/.config/opencode/skills/

# slash commands
cp -R commands/* ~/.config/opencode/commands/

# audit script — required by the `check` skill (path is hardcoded)
mkdir -p ~/.opencode/scripts
cp scripts/check-mechanical.py ~/.opencode/scripts/
```

### Project install

Drop `skills/*` into `.opencode/skills/` in your repo. OpenCode walks up from the working directory to the git worktree root and discovers matching `skills/*/SKILL.md` along the way. See the [skills discovery docs](https://opencode.ai/docs/skills/#understand-discovery).

## Notes

- The `check` skill references `~/.opencode/scripts/check-mechanical.py` via a hardcoded path. Deploy the script there (global install step above) for `check` to function.
- Skills are cross-referential (e.g. `check` suggests remedies via `spec`, `build`, `condense`). All 13 ship together so the references resolve.
- Skill frontmatter is OpenCode-native (`name`, `description`, `license: MIT`, `compatibility: opencode`). Names match their directory names per the [naming rules](https://opencode.ai/docs/skills/#validate-names).

## License

MIT — see [LICENSE](LICENSE).
