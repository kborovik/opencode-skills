---
description: GitHub release wrapper. Bumps the last git describe --tags tag (patch default; minor/major via AskUserQuestion), drafts notes from conventional-commit subjects since that tag, gates on AskUserQuestion before gh release create. Use when user asks to "cut a release", "publish a release", "tag a release", or "ship a version".
---

invoke the release skill: $ARGUMENTS