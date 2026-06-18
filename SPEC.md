# SPEC — opencode-skills

## §G GOAL
SDD skill pack for opencode — author, build, check, condense, design, reorganize a root `SPEC.md`; 13 cross-referential skills + 6 slash commands + 1 mechanical audit script ship together so intra-pack references resolve.

## §C CONSTRAINTS
- MIT license; opencode-native frontmatter (`name`, `description`, `license: MIT`, `compatibility: opencode`); skill dir name == frontmatter name.
- No global opencode config shipped (consumer responsibility).
- `check` skill references `~/.opencode/scripts/check-mechanical.py` via hardcoded path — deploy step required for check to function.
- Skills cross-referential — all 13 ship together or references dangle.
- LLM-facing surfaces (SPEC.md, SPEC-FORMAT.md, skill bodies) telegraph register; human-facing (README, issues, operator prose) steno.
- `check-mechanical.py` zero-dep (stdlib `hashlib`/`json` only); owns mechanical audits + memo + self-test.

## §I INTERFACES
- skill: `skills/<name>/SKILL.md` → 13 skills (spec, build, check, condense, design, reorganize, explain, commit, backprop, socratic, steno, telegraph, monitor)
- cmd: `commands/sdd-*.md` → 6 slash commands (sdd-spec, sdd-build, sdd-check, sdd-condense, sdd-design, sdd-reorganize)
- script: `scripts/check-mechanical.py` → mechanical audit core; subcmds `emit-overview`, `emit-v-slices`, `emit-superseded`, `--self-test`; deployed `~/.opencode/scripts/`
- format: `skills/spec/SPEC-FORMAT.md` → structural format reference (row schemas, section catalog, citation forms, archive sibling); consumed by spec/check/condense/reorganize via direct Read
- spec: `SPEC.md` @ repo root → sole live spec; authored by spec skill only
- archive: `SPEC.archive.md` @ repo root (optional) → immutable §T/§B/§V.retired rows
- renumber-map: `.opencode/spec-renumber-map.json` → append-only renumber history (written by reorganize, read by explain)
- clusters: `.opencode/spec-clusters.json` → reorganize cluster state

## §V INVARIANTS
V1: sole-source-of-truth — SPEC.md @ repo root sole live spec; not split, not docs/ tree, not JSON sidecars.
V2: monotonic-numbering — V<n>/T<n>/B<n> ids strictly increasing per section in doc order; gaps allowed (closure history); reuse forbidden. (? aliases monotonic-id `?`)
V3: freshness-contract — SPEC.md is clean current design; history lives in commit log + SPEC.archive.md; no inlined amendment-counters, dated-retirement clauses, or supersession-narration in live rows.
V4: status-flip — build skill flips §T status cell only (`.`↔`x`); task body not rewritten at status change.
V5: cite-resolution — cite-DAG edges: §T.cites→§V, §B.fix→§V, inline §V.<n> in §V/§C/§I→§V (cross-ref); check audits resolution + edge-type; spec mutation sweeps citers via edge-type traversal.
V6: fold-first-authoring — new §V row triggers decision-gate: fold into closest existing row vs split; split requires §B recurrence-class cite or orthogonal-concept declaration.
V7: design-lifecycle — design file persists in working tree post-fold-in; spec fold-in mutates SPEC.md only; user removes or preserves design file manually.
V8: skills-only — no hooks / runtime interception; skills are LLM self-report wrappers, not interceptors.
V9: response-shape — user-typeable SKILL.md carries `## Next` block (1–5 atomic positional-dispatch items); recipe ends at commit, dispatch is operator turn.
V10: sub-skill-flags — internal sub-skills (telegraph, backprop, socratic, steno, monitor) not directly invocable; auto-fire or programmatic only; description opens "Internal — not for direct invocation".
V11: dispatch — recipe-step-no-dispatch: skills never self-dispatch other skills mid-run; skill hand-off expressed only via `## Next` positional items, operator dispatches next turn.
V12: published-scope — PUBLISHED scope (skills/, commands/, scripts/, SPEC-FORMAT.md) bans pinned numeric §-cites (`§V.7`); use placeholder form (`§V.<n>`) or inline rule embedding. (? aliases published-tooling `?`)
V13: mechanical-realization — deterministic audit rules realized once in check-mechanical.py; not re-paraphrased per run; script regex is single source of truth; LLM re-derivation forbidden.
V14: mechanize-scan — every user-invocable SKILL.md carries byte-identical canonical MECHANIZE block; script audits byte-identity (DRIFT/MISSING) across the user-invocable set.
V15: scope-set — scope vocabulary {PUBLISHED, REPO-LOCAL, SPEC-ADJACENT, GITHUB-FACING}; invariants reduce audit touch-set; default full repo.
V16: drift-verdict-vocab — verdicts in {HOLD, VIOLATE, VIOLATE-CAPTURED, UNVERIFIABLE, SCOPE-EMPTY, HOLD-SINCE-CLEAN, LATENT}; format violations emit VIOLATE w/ `format:` evidence prefix.
V17: memo — check skill memo in REPO-LOCAL `.opencode/`; script owns both write + read ends; cache, not source of truth; invalidation on touched-set/diff change.
V18: single-load — check loads SPEC.md via script `emit-overview` (scope, not whole-file Read); §V bodies arrive via `emit-v-slices`; whole-file Read forbidden (token cap).
V19: batch — batch count script-computed from §V row count + PUBLISHED file census; `n=1` → main-thread single-agent; sub-agent parallel audit for `n>1`.
V20: read-only-diagnostic — check/explain read-only; sub-agent delegation safe; never mutate SPEC.md or code.
V21: tooling-preference — builtin Grep tool preferred over shell `grep`/`rg`; `grep -v -E` for invert scans; dedicated tools over shell pipes.
V22: verbatim-preservation — backtick-wrapped tokens, code, paths, URLs, identifiers, error strings, regex preserved verbatim; not pruned, not `\|`-escaped. (? aliases verbatim `?`)
V23: decision-gate — AskUserQuestion before any gh write or irrecoverable branch; mutually-exclusive action labels; no auto-file path.
V24: write-ownership — commits path-scoped (`git commit -m <subj> [-m <body>] -- <paths>`); pre-staged files never leak; `-m` flags precede `--`.
V25: write-serialize — SPEC.md-mutating writes serialize on main thread; classification/audit reads delegable to sub-agents.
V26: parametric-recipe — recipes parametric; repo-specific slugs/paths sourced from git remote / env at runtime, not hardcoded in skill body.
V27: github-facing-register — human-facing surfaces (README, GitHub issues, operator-facing diagrams) use steno; LLM-facing (SPEC.md, skill bodies) use telegraph.
V28: token-budget — SPEC.md token estimate `bytes/3.4`; >20k-token advisory triggers condense; >50 closed-§T rows triggers archive.
V29: token-budget-condense — token overflow resolved via archive sibling (SPEC.archive.md); archive carries immutable §T/§B/§V.retired rows; condense prunes history residue across live §V/§T/§B bodies.
V30: backprop-protocol — bug → spec skill BACKPROP records §B (+ §V if recurrence-class catchable) → build adds failing test named after invariant → fix code → commit citing §B/§V.
V31: monitor-protocol — skill-deviation auto-fire: REDACT (mandatory pre-publish) → ROUTE (dev repo → backprop hand-off, consumer repo → GitHub issue) → GATE (AskUserQuestion) → WRITE; no auto-file path; pre-write `--repo` assert.

## §T TASKS
id|status|task|cites
T1|.|reconcile pinned `§B.<n>` prose cites in PUBLISHED skill bodies vs published-scope ban (§B.7/§B.8/§B.14 referenced in skills/ + scripts/ comments)|V12
T2|.|reconstruct §B.7, §B.8, §B.14 rows from skill-body + check-mechanical.py references (cause/fix/date TBD w/ user)|V5,V13
T3|.|confirm §V alias-merges flagged `?` (V2 monotonic-id, V12 published-tooling, V22 verbatim) — single row or split?|V2,V12,V22

## §B BUGS
id|date|cause|fix
