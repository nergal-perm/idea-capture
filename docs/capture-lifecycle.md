# Capture identity, time, and lifecycle

Owner-approved decisions from the completed design discussion for
[issue #5](https://github.com/nergal-perm/idea-capture/issues/5).
This defines capture identity, time, and lifecycle. Attachment policies and
delivery mechanisms are specified in their respective decision tickets.

## Identity

A successful durable local save creates one capture. Delivery retries continue
that capture; a new save creates another capture even if its content is identical.
The system does not deduplicate captures by content. The vault owner resolves
repeated material while processing fleeting notes.

After saving, capture content and category cannot be edited, including while
waiting for delivery. A retry delivers the same unchanged capture.

## Composition

A capture contains up to one source-material block, up to one original comment,
and multiple attachments. Any part is optional, but at least one must be present.
Source material may include supplied text, a link, and available metadata; it
remains distinguishable from the author's comment.

## Category

A capture has one optional category applying to the whole capture. The available
categories are task, event, fact, emotion, idea, and question.

## Time

The date of capture is also treated as the date the thought arose. There is no
separate thought date or user-selected context date. Remembering a thought for
some time before capturing it does not introduce a second date.

Capture time is recorded on the originating device at save time, preserving its
local date and UTC offset. Delayed delivery and the server's timezone do not
change it: a capture saved on Friday and delivered on Monday retains its Friday
capture time.

## Observable lifecycle and local cleanup

Before confirmed delivery, clients show waiting for delivery, processing, or an
error with its reason and a retry action. Backend unavailability leaves captures
waiting. Successful durable local saving is confirmed immediately.

On confirmation that the resulting fleeting note has been created, the client
removes the capture from its queue and deletes its local data. No explicit
success message, notification, or delivered history is shown: the owner may
leave the client interface unopened for long periods. Cleanup does not depend
on opening the interface or seeing a confirmation. Delivered remains a domain
outcome, not a persistent client-visible state.

The owner can discard input before saving. After saving, a capture cannot be
cancelled; unwanted fleeting notes can be deleted during Inbox processing.

## Delivery after Inbox processing

Once a capture has produced a fleeting note, retries must not create another
note, including after the owner moves, processes, or deletes the original note.
Client cleanup after acknowledgement removes the normal opportunity to retry,
but cannot cover a lost acknowledgement: the client still holds the capture in
that case. Delivery acknowledgement and retry recognition mechanisms belong to
[issue #7](https://github.com/nergal-perm/idea-capture/issues/7).
