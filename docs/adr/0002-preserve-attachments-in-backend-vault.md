# Preserve attachments in the backend vault and stop at delivery

Store original attachments as ordinary files in per-capture directories inside
the backend's copy of the vault, linked relatively from the fleeting note;
publish the note only after every attachment is saved. This keeps the delivered
material together and prevents incomplete captures from appearing as successful
deliveries.

Idea Capture's responsibility ends at confirmed creation of that complete local
result. Further vault synchronization, access from other devices, processing,
and the eventual fate of notes and attachments belong to the vault workflow,
outside Idea Capture. Do not make attachment acceptance depend on downstream
synchronization rules or introduce a separate attachment-serving lifecycle.

These boundaries were agreed during
[issue #6](https://github.com/nergal-perm/idea-capture/issues/6); see the
[attachment policy](../attachments.md) for limits, intake, and cleanup rules.

## Refinement during issue #7

The owner subsequently chose post-delivery transcription for recorded spoken
comments: preserve and link the audio in the initial note, confirm delivery,
then add recognized text or a recognition error in the background, retaining
the source link. This is an explicit exception to stopping all backend work at
delivery; it does not bring vault synchronization or general note processing
into scope. See the [delivery contract](../delivery.md).
