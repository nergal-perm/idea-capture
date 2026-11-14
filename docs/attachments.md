# Attachment storage, limits, and retention

Owner-approved decisions from the completed design discussion for
[issue #6](https://github.com/nergal-perm/idea-capture/issues/6).
This document records the agreed file policy. Transfer, consistency, recovery,
and confirmation mechanisms belong to
[issue #7](https://github.com/nergal-perm/idea-capture/issues/7).

## Complete-capture delivery

A capture with attachments is delivered only when every original file has been
preserved and linked from the resulting fleeting note. The note appears in the
Inbox only after all attachments have been saved. Partial transfer is an
intermediate state, not partial delivery.

If one attachment fails, preserve the capture and its other files, keep the
complete capture on the client, and show the reason for failure. Do not silently
omit a file or confirm delivery of an incomplete capture.

## Storage and links

Store original files as ordinary files in a dedicated attachment directory
inside the backend's copy of the vault. Use relative links from the resulting
fleeting note. Preserve original content without extracting or interpreting
file contents.

Give each capture its own attachment directory. Preserve each original filename
as metadata and for display; use safe, unique on-disk filenames, retaining an
extension when present and adding a distinguishing suffix when needed. Files
with identical names remain separate attachments and never overwrite each other.
Delivery retries reuse the same files; a new capture gets its own copies.

Delivery responsibility ends with confirmed creation of the complete note and
preservation of all linked originals in the backend's copy of the vault.
Post-delivery transcription of recorded comments is the explicit additional
backend task described below. Further vault synchronization, availability on
other devices, and general processing of notes and attachments are outside
Idea Capture's scope. Attachment acceptance and storage
do not depend on downstream synchronization rules; no synchronization changes
or compatibility checks are required by Idea Capture.

## Retention and responsibility

Do not automatically expire delivered notes or attachments. Their subsequent
processing, movement, retention, and deletion belong to normal vault work,
outside Idea Capture. The explicit exception is backend transcription of a
recorded spoken comment and addition of its result to the delivered note; see
the [delivery contract](delivery.md). Moving or deleting a note does not trigger
attachment deletion by Idea Capture.

As already agreed in the [capture lifecycle](capture-lifecycle.md), the client
deletes its local capture and data after confirmed delivery. Before confirmation,
it retains the complete capture.

## Initial limits

The initial attachment limits are configurable:

- 100 MiB per file;
- 500 MiB of attachments per capture;
- 20 files per capture.

These are product defaults, not measured platform restrictions. Detect a limit
violation before confirming a successful local save and explain it explicitly.
Do not silently skip files.

## Local intake and editing before save

Confirm a successful local save only after all original files have been copied
into durable storage under the client's control. A source application's file
reference alone is insufficient because access or the source file may disappear.

Check attachment count and size before accepting the capture. Until a successful
local save, the author can edit the input and attachment selection, including
removing an oversized or inaccessible file, retrying, or discarding the input.
If any file cannot be copied or violates a limit, do not claim that the capture
was saved; keep the other input in the current form. Immutability starts only
after a successful local save.

## Storage exhaustion and waiting captures

Insufficient client storage blocks a new local save. Insufficient server storage
blocks completion of delivery and leaves the complete capture on the client.
Explain the failure and preserve already accepted data; do not evict earlier
captures to make room for new ones.

Waiting captures have no expiry. Initially there is no separate quota for the
whole client queue: available storage and per-capture limits constrain intake.
Changing limit settings does not invalidate captures already accepted.

## Interrupted transfers and recovery

The backend may delete intermediate files from an incomplete transfer, provided
that delivery can restore them from the complete client copy. Such cleanup must
not delete delivered attachments. Safe cleanup and retry/recovery mechanisms
belong to issue #7; this permission does not introduce expiry of saved captures.

## Audio attachments and spoken comments

An audio file supplied as an attachment is an original file: preserve it without
speech recognition, like any other attachment. A comment recorded through the
client's spoken-comment feature follows the separate speech pipeline. The
recording is preserved and linked in the initial delivered note; successful
background transcription adds text while retaining that original-audio link.
Further speech-pipeline details belong to issue #8.
