# Durable delivery and confirmation

Owner-approved decisions from the completed design discussion for
[issue #7](https://github.com/nergal-perm/idea-capture/issues/7).
This records the owner-confirmed delivery contract.
Capture identity and local cleanup follow the [capture lifecycle](capture-lifecycle.md);
file policies follow the [attachment policy](attachments.md).

## Persistent delivery records

Keep a separate durable record of delivered captures with no automatic expiry.
Store the capture identity and only the minimum information needed to validate
a retry and confirm the previous outcome, not a copy of note content or files.

A lost acknowledgement must not lead to a second note, including when the owner
has already moved, processed, or deleted the first note. A matching retry is
answered from the delivery record without recreating the note or its files.

Delivery records survive ordinary backend restarts. This does not introduce a
backup guarantee after server storage loss: the early-stage storage-loss
limitation in [ADR-0001](adr/0001-workstation-backend-and-inbox-lifecycle.md)
still applies.

## Processing independently of the client connection

After durably receiving all capture data, the backend completes processing
independently of the client connection or application remaining open.

Backend acceptance and completed delivery are distinct. The client retains its
complete local copy until confirmed delivery of the resulting complete note.

## Independent captures

An error or slow processing of one capture does not block others. Notes may
appear in a different order from local saves. Each retains its original capture
time; strict delivery ordering is not guaranteed.

## Capture description and retry identity

At local save, assign a permanent unique capture ID and form a versioned
description of the immutable content and metadata, including a file list with
sizes and checksums. Every retry uses the same identity and data. If an existing
ID is submitted with different content, report a conflict without overwriting
anything. Explicitly reject an unsupported format version; the client retains
the capture until incompatibility is resolved.

Use an HTTPS API reachable through Tailscale, with a versioned JSON capture
description, separate file uploads, and status queries by capture ID. Exact
endpoints, server libraries, and HTTPS setup remain technical design details.

## File transfer and integrity

Reuse fully received and verified files. Initially, retry an interrupted file
from its beginning rather than resuming at a byte offset. Other completed files
need not be resent. If intermediate server files have been cleaned up, request
and resend the missing files from the complete client copy. Verify each file's
size and checksum before accepting it as complete.

Byte-range resume can be added if practical testing demonstrates the need.

## Obtaining the outcome

The client can receive delivery confirmation in a server response or query
capture status by ID later. After a lost response, query status first: a delivered
capture receives its prior confirmation, while an unfinished capture continues
delivery. Persistent connections and server push notifications are not required.

## Errors and retries

Automatically retry transient failures with increasing intervals and a maximum
interval. Show failures requiring intervention with an understandable reason
and a retry action. An unavailable backend leaves the capture waiting. Storage
exhaustion and temporary processing failures can be retried after conditions
recover; identity conflicts and unsupported versions require the cause to be
fixed. Neither attempt count nor capture age causes deletion.

## Background delivery

Use the background opportunities allowed by each OS and restore the queue after
ordinary restarts. Do not promise delivery within a fixed time. Opening the
client must resume its queue. Before accepting each client, test background and
recovery scenarios and explicitly document situations requiring user action,
such as Android force-stop. The platform research is evidence of constraints,
not a substitute for those implementation checks.

## Uncertain publication outcomes

A crash can occur after the note becomes visible but before its delivered
record is committed. If the owner then moves or deletes the note, recovery may
be unable to distinguish this from a crash before the note ever appeared.
A durable intent alone does not prove publication.

When recovery cannot establish the outcome, do not automatically republish or
confirm delivery. Retain the complete client copy and report that result
verification and manual resolution are required. Other captures continue.
Fault-injection tests must cover this publication/record boundary.

After checking the outcome, the owner can explicitly confirm that delivery
already happened, recording delivery and permitting client cleanup, or authorize
a new publication attempt for the same capture ID. An ordinary automatic or
manual retry must not bypass this decision. The second action explicitly
authorizes publication despite the previously uncertain outcome.

## Recorded comments and post-delivery transcription

For a recorded spoken comment, preserve the original audio in the backend vault
and create the initial note with a link to it as soon as all capture files have
been saved. Confirm delivery at this point, without waiting for transcription;
normal client cleanup applies. Recognition runs as a background backend task.
Pending transcription work must survive ordinary backend restarts and must not
depend on the client retaining data after acknowledgement.

On successful recognition, supplement the note with the recognized comment,
retaining the original-audio link. On recognition failure, describe the failure
in the note so the owner can decide what to do next. Recognition failure does
not reverse delivery. Speech languages, quality, timing, and failure behavior
follow the [speech policy](speech.md).

### Note changes during recognition

Supplement only the original note while it remains in the Inbox. If the owner
has moved it out of the Inbox or deleted it, do not follow it through the vault
or recreate it. Record in the service log that the result could not be added
because the original note is no longer in the Inbox.

Put recognized text or an error in a separate backend-managed block, preserving
original text, links, and user additions. Retrying a background task must not
duplicate the block. If the owner has edited that block or a safe update is not
possible, preserve their changes and record the conflict rather than overwrite.

### Recognition failure after delivery

Once a final recognition error has been written to the note, the background task
ends. Do not retry indefinitely, reverse delivery, or return the capture to the
client queue. The client does not track post-delivery recognition. The note's
error and original-audio link let the owner decide what to do next. Make bounded
internal retries for transient recognition failures before declaring a final
error; see the [speech policy](speech.md).

## Implementation and acceptance follow-through

Exact API endpoints and schemas, identifiers and checksum encodings, numeric
retry intervals, durable-store technology, publication/recovery algorithms,
safe note-update mechanics, HTTPS setup, and platform scheduling mechanisms
are technical design details constrained by this contract. Stack choices belong
to issue #10 and staged acceptance to issue #11; speech implementation must
respect the [speech policy](speech.md) and delivery before recognition.

Validate offline saving and reconnects, ordinary client/backend restarts, lost
responses, concurrent retries, conflicting IDs, unsupported versions, file
integrity failures, missing intermediate files, storage exhaustion, and each
publication/record crash boundary. Include moved/deleted notes, uncertain-outcome
resolution, and transcription replay without duplicate blocks or overwriting
user changes. Real-device background/recovery checks are required per platform;
document any scenarios that require user action.
