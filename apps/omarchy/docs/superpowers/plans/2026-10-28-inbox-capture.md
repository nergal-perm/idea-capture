# Inbox Capture Implementation Plan

> **For agentic workers:** Execute inline with superpowers:executing-plans and TDD.

**Goal:** Switch desktop intake from daily bullets to temporary Inbox notes.
**Architecture:** QML retains a stable submission identity; Capture.js constructs
a JSON payload; capture.py generates a bounded title and atomically saves it.
**Tech Stack:** Existing QML/JS, Python 3 standard library, installed Codex CLI.
**Spec:** ../specs/2026-10-28-inbox-capture-design.md

## Global Constraints

- Preserve the exact input; do not write daily notes at intake.
- Use `YYYYMMDDHHmm` plus collision suffix as the ID and filename prefix.
- Luna low, eight-second inference budget, deterministic fallback.
- Preserve failed drafts and identity on retry; never overwrite another input.
- Preserve selected calendar date separately from real capture date.
- No Git repository exists here. Work on a temporary copy, then install after
  checks; do not create a repository or commit unrelated workspace content.

## Review Focus

- Concurrent/retried saves must not duplicate or overwrite inputs.
- Calendar dates and midnight must not falsify the time of capture.
- Model output must not become a path, shell command or changed source text.
- Model timeout/error must still permit capture; file errors must retain input.
- Successful save must clear identity and category, failed save must not.

### Task 1: Save helper

Files: create capture.py and test_capture.py.
Interface: JSON stdin `{id,text,category,capturedAt,contextDate}`; stdout JSON
`{id,path,title,titleSource}`; exit nonzero for file/identity/input errors.

- [x] Write and run failing temporary-vault integration tests for model titles,
  fallback, literal/multiline text, metadata, retries, conflicts and concurrency.
- [x] Implement validation, title generation, lock and no-clobber publication.
- [x] Run `python3 -m unittest -v test_capture.py` to green.

### Task 2: Desktop integration

Files: Capture.js, Capture.qml, Capture.test.js, Capture.qml.test.sh, Input.test.sh.
Interface: `saveCommand(text,category,createdAt,contextDate,id,helperPath)` returns
an argument array; QML allocates identity once and retains it until success or
a changed source draft. Existing event preview remains informational.

- [x] Replace obsolete daily-write assertions with failing Inbox assertions.
- [x] Integrate helper, actual timestamps, context date and retry identity.
- [x] Run Node and both real QML/keyboard checks in temporary vaults.

### Task 3: Install and verify

Files: README.md, manifest.json, menu-entry.json; calendar README/menu description.

- [x] Verify a real synthetic Luna title and document measured behavior.
- [x] Update docs and install tested plugin changes through the existing symlink.
- [x] Validate the plugin and QML; reload the installed plugin, preserving drafts.
- [x] Review the complete change and re-run checks affected by any fixes.

## Progress

The original implementation used an isolated temporary copy. The approved design is the binding
scope; no further planning approval or Git setup is needed for this local plugin.

Task 1: complete — 13 Python integrations green after observed failures.
Task 2: complete — 9 JS tests and real Wayland modal/keyboard tests green.
A lost-acknowledgement QML replay creates the note before reporting failure;
retry returns that same note. An observed error-label binding loop was removed
and the replay now checks that it does not recur.
Live synthetic Luna call: title returned in 3.73 seconds.
Final code review: no Critical/Important findings.
Task 3: complete — source installed, plugin/QML validated, final review and
post-fix checks passed. After the user unlocked the session, `omarchy restart
shell` completed successfully. Installed IPC status confirms `writeMode: inbox`,
`opened: false`, `busy: false`. No pending activation remains.
