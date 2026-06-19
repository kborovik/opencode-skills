# opencode-skills

SDD (spec-driven development) skill pack for [OpenCode](https://opencode.ai) — author, build, check, condense, design, reorganize, and explain a root `SPEC.md`.

A set of [agent skills](https://opencode.ai/docs/skills/) and slash commands that implement spec-driven development around a single root `SPEC.md`. Every row in the spec is addressable (`§V.<n>`, `§T.<n>`, `§B.<n>`); skills cross-reference each other and ship together so the references resolve.

## Install

This repo ships skills, slash commands, and the audit script. Global opencode config (e.g. `opencode.jsonc`, `default_agent`) is the consumer's responsibility and intentionally not included.

### Global install (recommended)

`install.sh` clones the repo into `~/.local/share/opencode-skills/` and symlinks skills, commands, and the audit script into their per-consumer target dirs. Re-running is idempotent; updates flow through via `git pull` in the clone.

```sh
curl -fsSL https://raw.githubusercontent.com/kborovik/opencode-skills/main/install.sh | sh
```

Override the repo (e.g. fork or local checkout) with `REPO=...`; override the ref with `REF=...`:

```sh
REPO=you/opencode-skills REF=main curl -fsSL https://raw.githubusercontent.com/kborovik/opencode-skills/main/install.sh | sh
```

Local checkout (developer install):

```sh
REPO="$(pwd)" ./install.sh
```

What gets deployed:

| source | target |
|---|---|
| `<clone>/skills` | `~/.config/opencode/skills` |
| `<clone>/commands` | `~/.config/opencode/commands` |
| `<clone>/scripts/check-mechanical.py` | `~/.opencode/scripts/check-mechanical.py` |

### Project install

Drop `skills/*` into `.opencode/skills/` in your repo. OpenCode walks up from the working directory to the git worktree root and discovers matching `skills/*/SKILL.md` along the way. See the [skills discovery docs](https://opencode.ai/docs/skills/#understand-discovery).

Slash commands resolve globally from `~/.config/opencode/commands/`; place them there (or via the global install above) for them to surface inside OpenCode.

## Commands

Slash commands are thin wrappers — frontmatter description distilled from the corresponding skill, body delegates via `invoke the <skill> skill $ARGUMENTS`.

| command | delegates to | what it does |
|---|---|---|
| `/sdd:spec` | `spec` skill | Sole `SPEC.md` mutator. Free-form intent; socratic gate classifies into NEW / DISTILL / BACKPROP / AMEND / FOLD-IN. |
| `/sdd:build` | `build` skill | Plan → execute → verify loop. `§T.n`, `--next`, or `--all`. |
| `/sdd:check` | `check` skill | Read-only drift report. Diffs `SPEC.md` vs code; groups violations by severity. Writes nothing (except `.opencode/check-state.json` memo on clean run per V32). |
| `/sdd:explain` | `explain` skill | Telegraph → prose. Decompresses one §-cite (`§V.<n>`, `§T.<n>`, `§B.<n>`, or `--next`). |
| `/sdd:condense` | `condense` skill | Token-budget sweep over `SPEC.md` (fold, archive, prune, rewrite). |
| `/sdd:design` | `design` skill | Propose-then-critique structural loop → `designs/<slug>.md`. |
| `/sdd:reorganize` | `reorganize` skill | Cluster + renumber §V rows; sweep cite-DAG. |

## Skills

13 skills ship together. User-typeable skills have a slash command; internal sub-skills auto-fire or are programmatic-only.

| skill | role | surface |
|---|---|---|
| `spec` | Sole semantic author of `SPEC.md` — create, amend, fold designs, backprop bugs. | `/sdd:spec` |
| `build` | Plan-then-execute implementation vs `SPEC.md`. | `/sdd:build` |
| `check` | Read-only drift detector. Diffs `SPEC.md` vs code, reports violations grouped by severity. | `/sdd:check` |
| `condense` | `SPEC.md` token-budget sweep. | `/sdd:condense` |
| `design` | Propose-then-critique structural design loop → `designs/<slug>.md`. | `/sdd:design` |
| `reorganize` | `SPEC.md` §V cluster + renumber + cite-DAG sweep. | `/sdd:reorganize` |
| `explain` | Telegraph → prose. Expand one `SPEC.md` citation into plain English. | `/sdd:explain` |
| `commit` | Commit staged changes with a Conventional Commits message. (No slash command — invokes inline. `## Next` block optional per V9 since dispatch is not post-commit.) | inline |
| `backprop` | Bug → spec protocol. Auto-fires on `/sdd:build` verification failures that smell like under-specification. | internal |
| `socratic` | Single-question intent-sharpening gate. Invoked by `/sdd:spec`. | internal |
| `steno` | Human-facing terse-prose register for non-author reviewers. | internal |
| `telegraph` | Telegraph encoding for `SPEC.md` and spec-adjacent writes. | internal |
| `monitor` | Skill-deviation auto-fire: captures misbehavior in sdd skills, routes to backprop or GitHub issue. | internal |

Skill frontmatter is OpenCode-native (`name`, `description`, `license: MIT`, `compatibility: opencode`). Names match their directory names per the [naming rules](https://opencode.ai/docs/skills/#validate-names).

## How to use

### Greenfield — new project

```
/sdd:design how should we shape the parser / renderer split?    # optional — only if structural questions
/sdd:spec build a static-site generator that converts a Markdown directory into a single-page HTML bundle
# review §G / §C / §I / §V in SPEC.md, amend if needed
/sdd:build --next    # plan, implement, verify T<n> (scaffold)
/sdd:build --next    # T<n> (renderer)
/sdd:check           # before opening a PR
```

### Brownfield — existing repo

```
/sdd:spec build the spec from this codebase                       # gate routes to DISTILL
/sdd:check                                                        # see what already drifts from the distilled spec
/sdd:spec V<n>'s bound is too loose for the rate-limiter         # gate routes to AMEND
/sdd:build §T.<n>                                                 # tackle a specific task
```

### A bug just hit production

```
/sdd:spec webhook handler retried POSTs after 5xx, double-charged 11 customers
# gate routes to BACKPROP: appends §B, usually adds a new §V, adds a §T fix task, commits SPEC.md
/sdd:build --next                                                 # failing test first, then the fix; commit cites §B / §V
/sdd:check                                                        # confirm the new §V is upheld
```

### Pre-merge sanity

```
/sdd:check
/sdd:explain §V.<n>    # if a violation is unclear, decompress it
```

## Files

```
opencode-skills/
├── commands/         7 slash commands (sdd-build, sdd-check, sdd-condense, sdd-design, sdd-explain, sdd-reorganize, sdd-spec)
├── scripts/          check-mechanical.py — deterministic audit core for `check`; test-install.sh smoke test
├── skills/           13 agent skills (one folder per skill, each with SKILL.md)
├── install.sh        global deploy: git clone + per-target symlinks (curl-bootstrap)
├── SPEC.md           sole live spec for this repo (authored by spec skill only)
├── .opencode/        repo-local state — check memo, plugin deps
└── README.md
```

## Notes

- The `check` skill references `~/.opencode/scripts/check-mechanical.py` via a hardcoded path. `install.sh` deploys it there (global install step above); without it, `check` will not function.
- Skills are cross-referential (e.g. `check` suggests remedies via `spec`, `build`, `condense`; `spec` invokes `socratic`; `build` invokes `backprop`). All 13 ship together so the references resolve.
- Slash commands are thin wrappers over skills — frontmatter description distilled from the matching `SKILL.md`, body delegates via `invoke the <skill> skill $ARGUMENTS`.
- This repo's own `SPEC.md` is authored by the `spec` skill; it tracks the same constraints the pack imposes on consumers.

## License

MIT — see [LICENSE](LICENSE).
