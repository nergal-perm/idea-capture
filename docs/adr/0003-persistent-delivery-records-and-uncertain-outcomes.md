# Retain delivery records and require resolution of uncertain publication

Keep minimal durable delivery records without automatic expiry, separately
from notes and attachments, so a retry can confirm the previous result after
the owner moves or deletes a note. A note's current absence cannot establish
that delivery never occurred; searching the vault is insufficient.

Publishing an ordinary Inbox file and committing its delivery record can leave
an uncertain outcome after a crash. When recovery cannot establish what happened,
retain the client copy and stop automatic publication and confirmation for that
capture until the owner explicitly confirms prior delivery or authorizes another
publication attempt. This favors avoiding automatic recreation of removed notes
over unconditional automatic completion after every crash, without imposing a
transaction protocol on the owner's vault workflow.

Agreed during [issue #7](https://github.com/nergal-perm/idea-capture/issues/7).
See the [delivery contract](../delivery.md) for the full behavior and required
crash-boundary checks; server-storage loss remains under ADR-0001's limitation.
