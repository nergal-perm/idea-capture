# Background capture titles

Approved user amendment: immediately save with a twelve-digit Zettelkasten ID
and first five words, then close the form and optionally rename in the
background. No random suffix. User selected next free minute on ID collisions;
actual capture time remains in capturedAt.

- [x] Test and implement immediate durable save, minute allocation and retries.
- [x] Test detached title worker: rename only the exact unchanged initial file,
  never overwrite a destination or resurrect a deleted/moved/processed note.
- [x] Adapt and test QML/JS, update docs, review, install and verify active plugin.

Technical decisions: filename is the sole title for new notes; omit duplicate
`name` metadata so optional naming is one atomic rename without rewriting the
source. Store an internal request token for retries in metadata, never in the
note ID or filename. Shared sync lock and Linux no-replace rename remain the
file boundaries. The original work used an isolated temporary copy before installation.

User refinement: no issued-ID accounting; use existing files only. Rejected the
review suggestion to keep a permanent registry. Retrying a moved extant note
still searches by its request token. No permanent deduplication after deletion.
Review repair: added post-rename fingerprint/inode verification and no-clobber
rollback of a detected edit at the boundary. Tested with an actual concurrent
content edit at the native rename boundary.

Complete: 19 Python integration tests and 9 JS tests pass; real QML lost-ack
retry and slow-model keyboard tests pass. Test fixtures now wait for detached
workers before deleting temporary directories. Plugin/QML validation passes.
Live synthetic observation: local save 0.186 s, background rename completed at
4.7 s. Installed version 0.4.0 and restarted shell; live IPC reports
writeMode=inbox and titleMode=background. No issued-ID registry created.
The specifically reported historical filename was already absent; no old note
was changed.
