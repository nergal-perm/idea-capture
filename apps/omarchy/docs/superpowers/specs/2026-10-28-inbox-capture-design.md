# Desktop capture into Inbox

Approved in conversation on 2026-10-28; naming refinement: use a twelve-digit
Zettelkasten `YYYYMMDDHHmm` prefix.

Enter saves a standalone `inbox_note` in `the configured Inbox directory`, without daily writes.
Keep the raw text verbatim, category, actual capture date/time, selected context
date and `processingStatus: unprocessed`. On the approved follow-up amendment,
IDs are exactly twelve digits (`YYYYMMDDHHmm`), without random suffixes. The
backend chooses the next free minute when an existing note occupies the ID.
Actual capture time remains separate. No issued-ID registry is maintained.

Save first with the first five words as a safe default filename, acknowledge
local durability and close the form. A detached GPT-6-Luna low worker may rename
the unchanged note after receiving a short title. An eight-second inference
budget applies only in the background. Failure leaves the initial name.
Filename is the sole title; duplicate `name` metadata is omitted. An internal
request token supports retries but is not a note ID or filename suffix.

A changed, moved, processed or deleted source must not be recreated by a worker.
Use initial content fingerprint and inode checks, the shared sync lock and an
atomic no-replace rename. Preserve detected concurrent edits. Arbitrary external
writers do not form a transaction with the plugin. Retries find extant captures;
no permanent history after deletion is introduced.

This amendment replaces the originally approved synchronous title wait and
random collision suffix at the user's explicit request. Historical notes are
not bulk migrated; the one specifically reported filename may be corrected.

Existing category, multiline keyboard behavior and length limit stay usable.
Update source/installed plugin descriptions and related calendar documentation.
No historical capture migration or review/closure automation is included.
