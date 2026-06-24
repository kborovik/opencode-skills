---
name: github
description: |
  Internal — not for direct invocation. Auto-fire gh-CLI workflow governor.
  Fires when an sdd skill or the operator runs a GitHub issue or pull-request
  operation — open an issue, start work on one, open a PR, merge a PR, or
  close one unmerged. Shapes the gh workflow: generic issue/PR structures,
  per-PR issue-linked branch, squash-merge with branch cleanup,
  `Closes #<issue>` linkage. Not for plain git ops (commit, push) nor
  `gh release` — the release skill owns version tag + release notes.
license: MIT
compatibility: opencode
---

# github — gh-CLI workflow governor (auto-fire)

Auto-fire sub-skill per the sub-skill-flags invariant (description opens
"Internal — not for direct invocation"; never `disable-model-invocation` —
that hides the skill from the Skill tool). No hook — the skills-only
invariant bans runtime interception; github = LLM-applied workflow shape on
each gh issue/PR op, not a wrapper. Ships PUBLISHED to every consumer →
governs the consuming repo's own gh workflow.

Trigger lives in this frontmatter description only — fires on a GitHub issue
or PR op, applies the gh-CLI shape per the github-workflow invariant. Body
LLM-facing → telegraph.

Repo-agnostic per the parametric-recipe invariant: every gh + git command
runs against the cwd repo — no hardcoded `owner/repo` slug, no `--repo`
flag, no repo-literal path. github-facing bodies (issue, PR) = steno per the
github-facing-register invariant; squash-merge commit subjects = fixed
templates, verbatim.

## FORMAT — GitHub-flavored Markdown

Format every git- and GitHub-related message with GitHub-flavored Markdown
(GFM). Applies to all human-facing surfaces this skill emits: issue titles
+ bodies, PR titles + bodies, commit message subjects + bodies (incl. the
squash-merge commit `gh pr merge` produces), release-adjacent notes, and
any branch or tag description. Rules:

- Fenced code blocks (`` ``` ``) for commands, paths, and verbatim output.
- `` `backticks` `` for identifiers, flags, file paths, and inline tokens.
- Bulleted lists for grouped items; `**bold**` for the one-line summary lead.
- `[text](url)` for links — never raw URLs when a link reads better.
  `Closes #<issue>` renders as a link in GitHub's renderer; keep the literal
  `Closes #<n>` token verbatim so GitHub auto-closes the linked issue.
- No HTML. No GFM heading markers (`#`) inside commit subjects — the subject
  line is plain imperative prose; GFM applies to the body and to issue / PR
  / release surfaces.
- Messages passed to `gh` via `--title` / `--body` / `--notes` flags are
  double-quoted; literal backticks and double quotes inside are escaped per
  shell rules so GFM survives the shell round-trip to GitHub's renderer.

## WHEN — fires on a gh issue/PR op:

- new issue requested → ISSUE
- start work on an issue (issue-linked branch) → BRANCH
- open a PR → PR
- merge a PR → MERGE
- close a PR unmerged → CLOSE

Not: plain git ops (commit, push) with no issue/PR, `gh release` (release
skill owns version tag + notes). No gh issue/PR op → no fire.

## ISSUE — `gh issue create`

`gh issue create --title "<summary>" --body <steno>` against the cwd repo
(no `--repo` slug per the parametric-recipe invariant). Title = one-line
summary; body = steno per the github-facing-register invariant, GFM-formatted
per FORMAT — problem statement + acceptance lines as a bulleted list, fenced
code for any command/path/output. No fixed template scaffold assumed.

## BRANCH — issue-linked branch

`gh issue develop <n> --checkout` — creates + checks out the issue-linked
branch in place (native gh linkage; branch named by gh, never hand-named).
One branch per session.

## PR — `gh pr create`

`gh pr create --title "<summary>" --body <steno>` from the linked branch.
Body = steno per the github-facing-register invariant, GFM-formatted per
FORMAT, + carries `Closes #<issue>` (links PR to issue; auto-closes the
issue on merge). Generic structure: change summary as a `**bold**` lead +
verification line, fenced code for diffs/commands. No fixed template
assumed.

## MERGE — squash + branch delete

`gh pr merge <n> --squash --delete-branch` — commits squashed to one, remote
branch deleted. The squash-merge commit subject + body follow the
conventional-commit template (fixed, verbatim); the body is GFM-formatted
per FORMAT when the skill supplies it.

`Closes #<issue>` in the PR body auto-closes the linked issue on merge → no
separate `gh issue close`.

## CLOSE — unmerged

PR abandoned, not merged → cleanup only, no squash:

1. `gh pr close <n>` — closes the PR, no merge commit.
2. `git branch -D <branch>` — local branch cleanup.

No squash, no `--delete-branch` merge path. The linked issue stays open —
nothing merged to close it.

## NON-GOALS

- No hook / runtime interception (skills-only invariant — no hooks).
- No `gh release` — the release skill (REPO-LOCAL) owns version tag + release
  notes.
- No hardcoded repo slug, no `--repo` flag — every op runs against the cwd
  repo (parametric-recipe invariant).
- Never edits SPEC.md or any skill body.