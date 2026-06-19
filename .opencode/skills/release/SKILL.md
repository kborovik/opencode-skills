---
name: release
description: |
  GitHub release wrapper. Bumps the last `git describe --tags` tag (patch
  default; minor/major via AskUserQuestion per decision-gate invariant), drafts
  notes from `git log <last-tag>..HEAD` conventional-commit subjects grouped by
  type, verifies local HEAD is pushed to upstream before `gh release create`
  (release-sync-precondition), gates on AskUserQuestion. Invoke when user
  asks to "cut a release", "publish a release", "tag a release", or "ship a
  version". Project-local — ships in-repo only, not deployed by `install.sh`.
license: MIT
compatibility: opencode
---

# release — cut a GitHub release

Bump the last tag, draft notes from conventional-commit subjects since that
tag, gate on AskUserQuestion, then `gh release create`. Irrecoverable
operation (published tag) → decision-gate invariant fires pre-create.

## LOAD

1. `git describe --tags` → last tag string. Absent (no tags yet) →
   `last_tag=""`, `last_tag_arg="HEAD"` (notes cover full history). Present →
   `last_tag_arg=<last-tag>`.
2. `git log --format='%s' <last-tag-arg>..HEAD` → conventional-commit subjects
   since the last tag (or full history when no prior tag).
3. Parse subjects into type buckets per Conventional Commits:
   - type prefix = substring before `(` scope or `:` subject sep, lowercased.
   - buckets: `feat`, `fix`, `chore`, `refactor`, `docs`, `test`, `style`,
     `perf`, `build`, `ci`, `other` (no `type:` prefix → `other`).
4. Compute next tag:
   - last tag absent → `v0.1.0` (first release default).
   - last tag `vMAJOR.MINOR.PATCH` (strip leading `v`, suffixes like `-rc.1`
     trimmed) → bump:
     - patch (default): `vMAJOR.MINOR.PATCH+1`
     - minor: `vMAJOR.MINOR+1.0`
     - major: `vMAJOR+1.0.0`
   - unparseable last tag → AskUserQuestion to confirm the next tag string
     (free-form), header `Tag-bump fallback`.

## GATE

AskUserQuestion pre-`gh release create` (decision-gate invariant — published
tag is irrecoverable). One question, header `Release create`:

- question: `Create release <next-tag> with <N> commit subjects since
  <last-tag-or-start>?`
- options (mutually exclusive):
  - "Patch bump — create <next-tag>" (recommended; default)
  - "Minor bump — create <vMAJOR.MINOR+1.0>"
  - "Major bump — create <vMAJOR+1.0.0>"
  - "Cancel — do not create"

Operator selects → proceed. Cancel → stop, no `gh` call, no tag mutation.

## SYNC

Release-sync-precondition (per §V.<n>) — fires after GATE approval, before
CREATE. Published tag points at the commit `gh release create` resolves on the
remote; if local HEAD is ahead of upstream, the tag lands on the stale remote
HEAD while release notes (drafted from local `git log`) cover unpushed
commits — release contents and notes diverge. Guard:

1. Resolve upstream branch: `git rev-parse --abbrev-ref @{u}`. No upstream
   configured (new branch, bare clone w/o tracking) → AskUserQuestion, header
   `Push-target fallback`, confirm the `<remote>/<branch>` to push; operator
   may cancel.
2. Compare `git rev-parse HEAD` vs `git rev-parse @{u}`:
   - equal → synced; proceed to CREATE.
   - local ahead → `git push <remote> <branch>`; on push failure (rejected
     non-fast-forward, auth) → abort w/ "push failed; resolve then re-invoke".
   - local behind or diverged → abort w/ "local and upstream diverged;
     rebase/merge, re-invoke after sync".
3. Uncommitted working tree (`git status --porcelain` non-empty) → abort w/
   "working tree dirty; commit or stash, re-invoke". `gh release create` tags
   HEAD regardless of working-tree state so dirty tree does not corrupt the
   tag, but a dirty tree usually means the operator has unfinished work that
   should not ship under the release commit; the guard surfaces this pre-tag.

Tag push not done here — `gh release create` is the publish act and pushes the
tag itself; SYNC pushes the branch only so the tag points at a commit upstream
already has.

## NOTES

Release notes body — grouped Conventional Commits subjects, telegraph
register (LLM-facing per github-facing-register exception: release notes are
GitHub-facing → steno, but the SKILL.md body itself is LLM-facing → telegraph).
One section per non-empty bucket, heading `### <type>`; subjects verbatim,
one bullet each, dedup identical subjects (first-wins, order preserved).

Skeleton:

```
## What's new

### feat
- <subject>

### fix
- <subject>

### chore
- <subject>

## Full diff: https://github.com/<owner>/<repo>/compare/<last-tag>...<next-tag>
```

`<owner>/<repo>` resolved via `git remote get-url origin` at runtime (no
hardcoded repo path — parametric-recipe invariant). Remote absent → omit the
compare link line.

## CREATE

1. `gh release create <next-tag> --notes "<notes body>" --title "<next-tag>"`
   (no `--target` — HEAD is the release commit; no prerelease flags unless the
   operator supplied one at the GATE).
2. Relay single line: `<next-tag> created — <URL>` (`gh` prints the release
   URL on stdout; capture and relay verbatim, no preamble).

## MECHANIZE — script-candidate scan

Recipe end → before the `## Next` block, scan this run for a mechanization candidate. Candidate = any of:

- ≥ 2 same-shape deterministic calls this run (identical command modulo args)
- LLM-side join / sort / count / dedup over script-emittable data
- multi-step parse collapsible to one script emit mode
- fresh regex paraphrase of an existing mechanical rule (mechanical-realization invariant class)

Hit → emit exactly one `## Next` item naming the observed pattern + proposed script mode; none → no item. Never self-implement the mechanization mid-run (recipe-step-no-dispatch + write-ownership invariants). Route by cwd:

- dev repo (this skill pack) → invoke the spec skill → new §T row
- consumer repo → invoke the spec skill → `.opencode/check-extras` row

## OUTPUT — "Next" block

Heading `## Next`; 1–5 atomic items (one sentence each, no `Reply` prefix); positional dispatch (`run <int>` or `invoke the <skill-name> skill [args]`). Optional `## Hint` (≤ 3 lines) precedes when item selection needs hidden state. Published tag → follow-ups audit + next release prep.

```
## Next

1. invoke the check skill — audit the just-published tag's spec-vs-code drift
2. invoke the release skill — cut the next release when new commits land
```

## NON-GOALS

- No `git tag` direct — `gh release create` tags implicitly; a bare `git tag`
  would diverge from the release object.
- No changelog file writes. Release notes live in the GitHub release, not a
  `CHANGELOG.md` (freshness-contract invariant — history in commit log + GitHub
  release, not in-tree).
- No auto-push of the tag. `gh release create` is the publish act (and pushes
  the tag). SYNC step pushes the branch only — see SYNC.
- No bump-files (`package.json` version, etc.) — version lives in tags only.