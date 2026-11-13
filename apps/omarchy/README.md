# Inbox Capture for Omarchy

Open **Idea Capture** from the Omarchy menu (Super+Space, type `idea`).
Enter a thought, optionally select `task`, `event`, `fact`, `emotion`, `idea`,
or `question`, and press Enter. The plugin creates one temporary Markdown note
in the configured Inbox directory. Intake creates no daily note or daily link.

## Notes and names

A filename initially has this form:

```text
202610281805 First five words of capture.md
```

The ID is exactly the vault's Zettelkasten `YYYYMMDDHHmm`, with no random suffix.
If that minute is occupied by an existing note, choose the next free minute.
Actual capture time stays in `capturedAt`; ID allocation does not rewrite it.
There is no issued-ID registry or permanent reservation history.

The helper saves and verifies this initial note before returning. The form
closes immediately after local save. A detached worker then asks Luna for a
short title and atomically renames the file, retaining the same twelve-digit ID.
No answer, timeout, model failure or rename collision leaves the initial name.
The filename is the sole title; new notes omit duplicate `name` metadata so a
title change requires no content rewrite. A separate `captureRequestId` in
metadata identifies retries and is never part of the filename or note ID.

The input is preserved verbatim under the original-input heading, including
explicit newlines and leading/trailing whitespace. Metadata records
`type: inbox_note`, `processingStatus: unprocessed`, category, actual local
`capturedOn`/`capturedAt`, and the separately selected `contextDate`.
Calendar dates are context, not the time of creation or a task deadline.
The `task` and `event` categories are raw hints, not accepted obligations.

GPT-6-Luna with low reasoning generates only the short name from the full
input through the installed Codex CLI. No tools, repository instructions,
plugins, apps, hooks or memories are enabled for that invocation. It runs in
an isolated temporary working directory with structured JSON output and an
eight-second timeout. The existing Codex authentication is used; no API key
is copied into the plugin. Captured text goes to the model over stdin, never
as a shell command. The title is normalized to a safe filename, at most eight
words / 64 characters / 180 UTF-8 bytes. The raw source is never rewritten.

A synthetic live test on 2026-10-28 saved the initial file in 0.19 seconds,
then renamed it with a Luna title after 4.7 seconds. These are observations,
not latency guarantees. Inference never blocks the initial save.

## Interaction and reliability

Enter saves; Shift+Enter inserts a newline. The wrapped input grows and shrinks,
scrolls at the screen-height limit and accepts at most 8,000 characters.
For `event`, a valid leading time such as `19:30 Musical` is recognized in an
informational preview; the original text, including that time, remains intact.
Malformed times stay literal and show a non-blocking hint.

While saving, input is read-only and duplicate submissions are ignored.
Success closes the modal, clears the draft and resets the category. File
errors keep the draft and its submission token/time for retry. Retrying the
same submission finds the existing note, including after background renaming.
A retry can also find a note moved elsewhere in the vault. After deletion no
permanent receipt is retained; no all-time deduplication claim is made.
Changing text, category or context date starts a new submission identity.
Independent captures of identical text remain separate notes.

Escape/outside click hides the overlay without cancelling an in-flight save.
A successful background save clears its draft. Dismissed drafts retain their
category. Drafts remain in memory; preserve them before restarting the shell.

The Python helper coordinates file writes with the existing
configured lock file, writes/fsyncs a temporary file and publishes
it with a no-clobber hard link before verifying the saved bytes. Model requests
run outside that lock in detached processes with no inherited output pipes.
A worker checks the original fingerprint, inode and unprocessed state, then
uses Linux `renameat2(RENAME_NOREPLACE)` under the lock. Changed, moved or deleted
notes are skipped, never recreated. A detected edit at the rename boundary
restores the original filename without overwriting another file. Arbitrary
non-cooperating concurrent editor actions are not a distributed transaction.
If the shell restarts after local save, the detached worker can finish independently.

## Installation and configuration

Requires Omarchy 4 / Quickshell with `qs.Ui` and `qs.Commons`, Python 3.12+, Linux/glibc with `renameat2`, and
Node/Bash for tests. Codex CLI is optional for model titles: unavailable
inference uses the fallback. There are no additional Python packages.

Install a symlink named `eugene.daily-capture` in Omarchy's user plugin
directory, pointing to this `apps/omarchy` directory wherever the repository
is checked out. The legacy plugin ID preserves menu and calendar compatibility.
`capture.py`
is invoked with Python from the plugin directory; intake no longer uses
`create-daily.sh` or `append-to-section.sh`.

```bash
omarchy plugin validate .
omarchy-shell shell rescanPlugins
omarchy-shell eugene.daily-capture status
```

If the shell retains cached code, use `omarchy restart shell` after preserving
any drafts. Initial menu installation uses `menu-entry.json` in the user's
Omarchy menu extension.

Copy [config.example.toml](config.example.toml) to the user configuration
directory as `idea-capture/config.toml` and replace the sample values.
The directory is selected by `XDG_CONFIG_HOME`, falling back to the user's
`.config` directory. `CAPTURE_CONFIG` selects a different configuration file.
Keep the real configuration outside the checkout, readable only by its owner.

Configuration keys:

- `vault`: required path to the notes root. No workspace layout is inferred.
- `inbox`: directory relative to `vault`, or an absolute directory inside it;
  default `inbox`. Paths escaping the notes root are rejected.
- `lock_file`: shared lock path. Use the same lock as any cooperating sync
  process. If omitted, a standalone `.capture.lock` inside the notes root is used.
- `codex`: optional executable path; otherwise Codex is discovered on `PATH`.
  An unavailable executable deliberately uses the fallback title.

Paths accept a leading `~`. Set `vault` and `lock_file` to absolute paths or
home-relative paths; a relative `inbox` is resolved inside the configured root.
CLI options `--vault`, `--inbox`, `--lock-file` override the respective
`CAPTURE_VAULT`, `CAPTURE_INBOX`, `CAPTURE_LOCK_FILE` environment settings, which
override TOML. `CAPTURE_CODEX` overrides the configured executable.
`CAPTURE_TITLE_TIMEOUT` sets positive seconds, up to 30; default 8.
The helper reads configuration for each submission; detached workers receive
the selected storage paths explicitly. Without a configured root, saving fails
and the form retains the draft.

Summon accepts JSON `date` (`YYYY-MM-DD`) and optional `category`. Omitting date
uses the local date at opening. Malformed requests do not open the modal.
The selected context date remains fixed across midnight. A request during a
save is ignored. `status` reports `writeMode: inbox`, visibility, busy state,
context date, category and last result without source text. `formatPreview`
formats a synthetic informational bullet without writing.

## Validation

```bash
python3 -m unittest -v test_capture.py
node --test --test-isolation=none Capture.test.js
bash Capture.qml.test.sh
bash Input.test.sh
omarchy plugin validate .
qmlformat Capture.qml >/dev/null
```

For graphical tests, set `OMARCHY_PATH` to the installed Omarchy data directory
or `CAPTURE_OMARCHY_SHELL` to its `shell` directory. Test storage and title
commands are isolated from the user's configuration. If `qmlformat` is not on
`PATH`, invoke the formatter from the installed Qt tooling directory.

Python tests run the real helper against temporary vaults with a fixture Codex
executable at the inference boundary. They cover success, failure, malformed
output, timeout, unsafe/long Unicode titles, literal source preservation,
retries, minute collisions, concurrent saves, moved/edited/deleted notes,
rename destination collisions and the no-overwrite boundary.
QML tests use real modal/keyboard behavior and temporary vaults, disable real
inference, and verify no daily files are created. Run graphical tests in the
local Wayland session; they require its runtime socket permissions.
