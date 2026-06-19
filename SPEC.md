# SPEC — opencode-skills

## §G GOAL
SDD skill pack for opencode — author, build, check, condense, design, reorganize a root `SPEC.md`; 13 cross-referential skills + 6 slash commands + 1 mechanical audit script ship together so intra-pack references resolve.

## §C CONSTRAINTS
- MIT license; opencode-native frontmatter (`name`, `description`, `license: MIT`, `compatibility: opencode`); skill dir name == frontmatter name.
- No global opencode config shipped (consumer responsibility).
- `check` skill references `~/.opencode/scripts/check-mechanical.py` via hardcoded path — `install.sh` deploys script there; required for `check` to function.
- Skills cross-referential — all 13 ship together or references dangle.
- LLM-facing surfaces (SPEC.md, SPEC-FORMAT.md, skill bodies) telegraph register; human-facing (README, issues, operator prose) steno.
- `check-mechanical.py` zero-dep (stdlib `hashlib`/`json` only); owns mechanical audits + memo + self-test.
- install model — global install: `git clone` to `~/.local/share/opencode-skills/` + per-file symlink for each entry under `<clone>/skills/`, `<clone>/commands/`, `<clone>/scripts/` into per-consumer target dirs (`~/.config/opencode/skills/<name>`, `~/.config/opencode/commands/<name>`, `~/.opencode/scripts/<name>`); updates via `git pull` in clone target flow through symlinks; `install.sh` curl-bootstrappable from repo `main`.

## §I INTERFACES
- skill: `skills/<name>/SKILL.md` → 13 skills (spec, build, check, condense, design, reorganize, explain, commit, backprop, socratic, steno, telegraph, monitor)
- cmd: `commands/sdd-*.md` → 7 slash commands (sdd-spec, sdd-build, sdd-check, sdd-condense, sdd-design, sdd-reorganize, sdd-explain)
- script: `scripts/check-mechanical.py` → mechanical audit core; subcmds `audit`, `write-memo`, `emit-v-slices`, `emit-superseded`, `emit-fold-seeds`, `emit-v-weights`, `emit-row-ids`, `emit-overview`, `emit-token-estimate`; flag `--self-test`; deployed `~/.opencode/scripts/`
- script: `install.sh` → global deploy: `git clone` to `~/.local/share/opencode-skills/` (skip if exists) + per-file symlink for each `<clone>/skills/<name>` → `~/.config/opencode/skills/<name>`, `<clone>/commands/<name>` → `~/.config/opencode/commands/<name>`, `<clone>/scripts/<name>` → `~/.opencode/scripts/<name>`; idempotent re-run, `curl | sh` bootstrap supported
- format: `skills/spec/SPEC-FORMAT.md` → structural format reference (row schemas, section catalog, citation forms, archive sibling); consumed by spec/check/condense/reorganize via direct Read
- spec: `SPEC.md` @ repo root → sole live spec; authored by spec skill only
- archive: `SPEC.archive.md` @ repo root (optional) → immutable §T/§B/§V.retired rows
- renumber-map: `.opencode/spec-renumber-map.json` → append-only renumber history (written by reorganize, read by explain)
- clusters: `.opencode/spec-clusters.json` → reorganize cluster state
- check-state: `.opencode/check-state.json` → check skill memo (auto-committed on clean run per V32)

## §V INVARIANTS
V1: sole-source-of-truth — SPEC.md @ repo root sole live spec; not split, not docs/ tree, not JSON sidecars.
V2: monotonic-numbering — V<n>/T<n>/B<n> ids strictly increasing per section in doc order; gaps allowed (closure history); reuse forbidden.
V3: freshness-contract — SPEC.md is clean current design; history lives in commit log + SPEC.archive.md; no inlined amendment-counters, dated-retirement clauses, or supersession-narration in live rows.
V4: status-flip — build skill flips §T status cell only (`.`↔`x`); task body not rewritten at status change; flip is the §T-row closure record, decision + work live in prior spec/code commits (body unchanged per §V.3 freshness-contract).
V5: cite-resolution — cite-DAG edges: §T.cites→§V, §B.fix→§V, inline §V.<n> in §V/§C/§I→§V (cross-ref); check audits resolution + edge-type; spec mutation sweeps citers via edge-type traversal.
V6: fold-first-authoring — new §V row triggers decision-gate: fold into closest existing row vs split; split requires §B recurrence-class cite or orthogonal-concept declaration.
V7: design-lifecycle — design file persists in working tree post-fold-in; spec fold-in mutates SPEC.md only; user removes or preserves design file manually.
V8: skills-only — no hooks / runtime interception; skills are LLM self-report wrappers, not interceptors.
V9: response-shape — user-typeable SKILL.md carries `## Next` block (1–5 atomic positional-dispatch items); recipe ends at commit, dispatch is operator turn; exception `commit` skill w/o follow-up dispatch surface — `## Next` block optional (closes §B.2).
V10: sub-skill-flags — internal sub-skills (telegraph, backprop, socratic, steno, monitor) not directly invocable; auto-fire or programmatic only; description opens "Internal — not for direct invocation" (frontmatter description detection handles YAML 1.2 block-scalar continuation lines; closes §B.15).
V11: dispatch — recipe-step-no-dispatch: skills never self-dispatch other skills mid-run; skill hand-off expressed only via `## Next` positional items, operator dispatches next turn.
V12: published-scope — PUBLISHED scope (skills/, commands/, scripts/, SPEC-FORMAT.md) bans pinned numeric §-cites (`§V.7`); use placeholder form (`§V.<n>`) or inline rule embedding.
V13: mechanical-realization — deterministic audit rules realized once in check-mechanical.py; not re-paraphrased per run; script regex is single source of truth; LLM re-derivation forbidden.
V14: mechanize-scan — every user-invocable SKILL.md carries byte-identical canonical MECHANIZE block; script audits byte-identity (DRIFT/MISSING) across the user-invocable set; exempt internal sub-skills w/o corresponding slash-command (`backprop`, `monitor`, `socratic`, `steno`, `telegraph`) and the `commit` skill per V9 no-dispatch exception — MECHANIZE block inapplicable when no command dispatch follows (closes §B.1).
V15: scope-set — scope vocabulary {PUBLISHED, REPO-LOCAL, SPEC-ADJACENT, GITHUB-FACING}; invariants reduce audit touch-set; default full repo.
V16: drift-verdict-vocab — verdicts in {HOLD, VIOLATE, VIOLATE-CAPTURED, UNVERIFIABLE, SCOPE-EMPTY, HOLD-SINCE-CLEAN, LATENT}; format violations emit VIOLATE w/ `format:` evidence prefix.
V17: memo — check skill memo in REPO-LOCAL `.opencode/`; script owns both write + read ends; cache, not source of truth; invalidation on touched-set/diff change.
V18: single-load — check loads SPEC.md via script `emit-overview` (scope, not whole-file Read); §V bodies arrive via `emit-v-slices`; whole-file Read forbidden (token cap).
V19: batch — batch count script-computed from §V row count + PUBLISHED file census; `n=1` → main-thread single-agent; sub-agent parallel audit for `n>1`.
V20: read-only-diagnostic — check/explain read-only; sub-agent delegation safe; never mutate SPEC.md or code.
V21: tooling-preference — builtin Grep tool preferred over shell `grep`/`rg`; `grep -v -E` for invert scans; dedicated tools over shell pipes.
V22: verbatim-preservation — backtick-wrapped tokens, code, paths, URLs, identifiers, error strings, regex preserved verbatim; not pruned, not `\|`-escaped.
V23: decision-gate — AskUserQuestion before any gh write or irrecoverable branch; mutually-exclusive action labels; no auto-file path.
V24: write-ownership — commits path-scoped (`git commit -m <subj> [-m <body>] -- <paths>`); pre-staged files never leak; `-m` flags precede `--`.
V25: write-serialize — SPEC.md-mutating writes serialize on main thread; classification/audit reads delegable to sub-agents.
V26: parametric-recipe — recipes parametric; repo-specific slugs/paths sourced from git remote / env at runtime, not hardcoded in skill body.
V27: github-facing-register — human-facing surfaces (README, GitHub issues, operator-facing diagrams) use steno; LLM-facing (SPEC.md, skill bodies) use telegraph.
V28: token-budget — SPEC.md token estimate `bytes/3.4`; >20k-token advisory triggers condense; >50 closed-§T rows triggers archive.
V29: token-budget-condense — token overflow resolved via archive sibling (SPEC.archive.md); archive carries immutable §T/§B/§V.retired rows; condense prunes history residue across live §V/§T/§B bodies.
V30: backprop-protocol — bug → spec skill BACKPROP records §B (+ §V if recurrence-class catchable) → build adds failing test named after invariant → fix code → commit citing §B/§V.
V31: monitor-protocol — skill-deviation auto-fire: REDACT (mandatory pre-publish) → ROUTE (dev repo → backprop hand-off, consumer repo → GitHub issue) → GATE (AskUserQuestion) → WRITE; no auto-file path; pre-write `--repo` assert.
V32: check-memo-commit — on clean audit (V17 memo-gate: no VIOLATE/UNVERIFIABLE/UNRESOLVED/TYPE-MISMATCH/DRIFT/MISSING/STALE/EXTRA), check skill auto-commits `.opencode/check-state.json` (path-scoped per V24), no operator prompt; exemption to V20 read-only-diagnostic for this file only.

## §T TASKS
id|status|task|cites
T3|x|confirm §V alias-merges flagged `?` (V2 monotonic-id, V12 published-tooling, V22 verbatim) — single row or split?|V2,V12,V22
T4|x|author `scripts/install.sh` — global deploy per install-model: `git clone` to `~/.local/share/opencode-skills/` + symlink into `~/.config/opencode/{skills,commands}/` and `~/.opencode/scripts/check-mechanical.py`; idempotent, `curl | sh` bootstrap|I.script,V26
T5|x|move `install.sh` from `scripts/` to repo root; refresh bootstrap URL + test-script path; preserve T4 closure history|I.script
T6|x|add `commands/sdd-explain.md` — slash command mirroring explain skill (description-only frontmatter distilled from `skills/explain/SKILL.md`, body delegates via `invoke the explain skill $ARGUMENTS`) per V9 response-shape contract|I.cmd,V9
T7|x|per-file symlinks in install.sh — replace bulk dir-symlinks (`skills/`, `commands/`) + single-script symlink w/ iteration over each entry in `<clone>/skills/*`, `<clone>/commands/*`, `<clone>/scripts/*` → per-file symlink via existing `link()` helper; preserves idempotency + `curl|sh` bootstrap|I.script,V26
T8|x|fix `scripts/check-mechanical.py` `emit-row-ids` §I extraction — drops hyphenated kinds (`renumber-map`, `check-state`); V13 regex single source of truth|V13
T9|x |fix `scripts/check-mechanical.py` `is_user_invocable` YAML 1.2 block-scalar parsing — strip indent from `description: |` continuation lines, prefix-match `Internal` on any continuation line; covers §B.1 + §B.2 false-positive MISSING|I.script,V10,B15

## §B BUGS
id|date|cause|fix
B1|2026-06-17|mechanize-scan false-positive RECURRING — 5 internal sub-skills (backprop, socratic, steno, telegraph, monitor) flagged user-invocable MISSING every check run despite V10-compliant description prefix; root-cause class in §B.15|V14
B2|2026-06-17|original capture reversed — commit SKILL.md authored legitimately w/o MECHANIZE + `## Next` blocks (V9 no-dispatch exception); same root-cause class as §B.1 captured in §B.15 (commit mis-classified user-invocable by `is_user_invocable`); path-scoping enforced via staged-index discipline (step 3) not commit-cmd flag pattern|V9,V24
B7|2026-06-17|batch agent count eyeballed from repo-file census — LLM hand-computed heuristic, non-deterministic across runs|V19
B8|2026-06-17|LLM silently remaps out-of-type verdict (MATCH on §V, V-vocab on §I) — no per-row-type admissibility gate|V16
B14|2026-06-17|skill body instructs operator to directly invoke internal sub-skill — sub-skill set hand-grepped from bodies, over-matches prose mentions|V9,V10
B15|2026-06-18|audit-script `is_user_invocable` mis-parses YAML 1.2 block-scalar descriptions — returns user-invocable when `description: |` opens multi-line value, never inspects continuation lines for V10 `Internal` prefix; root cause of §B.1 (5 internal sub-skills) + §B.2 (commit) recurring MISSING|V10
