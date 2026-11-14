# Capture and queue interaction

Owner-approved decisions from the completed interaction discussion for
[issue #9](https://github.com/nergal-perm/idea-capture/issues/9).
The owner reviewed the disposable sketch, accepted its scenarios and behavior,
and refined selected-text intake and source identification across all three
platforms. The owner confirmed publication of the outcome and closure of #9.

## Entry points and screens

Capture and delivery queue are separate screens. Fast entry points, such as a
desktop shortcut or an operating-system Share action, open the capture form.
Opening the application's main UI shows the delivery queue, which also offers
an action to open the capture form. Exact native entry points may differ while
capabilities remain equivalent.

Use one capture form for direct entry and shared input. Shared source material
and files are already present; the author can add typed text, one speech
recording, attachments, and an optional category. One Save action saves the
complete capture without an additional confirmation screen. Missing source
metadata does not require manual completion or block saving.

## Selected text and source identity

Support capturing an exact selected passage into a separate source-material
field on Omarchy, Android, and macOS, with the author's own thought entered
separately. Source applications may be browsers, readers, editors, or other
applications; Zotero is an example, not a required special integration.

Preserve available context identifying the source: a page or document title,
URL, originating application, and open filename when available. For a passage
from a book, the author needs to identify the book as well as retain the exact
passage. An application name or filename alone is not a guaranteed book title.
Do not invent unavailable context or assume that a Share action supplies all
of it. Platform intake mechanisms and actual payloads require verification
before the affected implementation stage.

Automatically populate available source context. If a title or source link is
missing, make that absence visible and offer optional manual completion before
saving. Missing source identity does not block capture or require manual entry.
Keep manually supplied context distinguishable from context received from the
source application; never imply that an unavailable title or link was detected.

### Platform evidence and limits

Android's [EXTRA_TEXT](https://developer.android.com/reference/android/content/Intent#EXTRA_TEXT)
is literal text sent by the source, not a guarantee of its current selection or
document identity. The sharing payload depends on the sending application.
Apple's [NSExtensionItem](https://developer.apple.com/documentation/foundation/nsextensionitem)
provides optional title, content text, and attachment properties; these do not
guarantee a selected passage and identifying title or URL in every application.
These are documented API limits, not real-device integration results.

On Wayland, clipboard and primary-selection data do not guarantee a document
title or URL; see the [wl-clipboard manual](https://github.com/bugaevc/wl-clipboard/blob/master/data/wl-clipboard.1).
Native intake integration must be checked on the target devices before the
affected stage: use representative browser and reader sources, distinguish
sharing a selection from sharing an entire document, and inspect the actual
text and metadata supplied. Do not promise complete automatic context across
arbitrary source applications. These checks do not expand scope to OCR, file
content extraction, or mandatory app-specific integrations.

## Unsaved drafts

Dismissing the capture form may retain its unsaved input in memory so the author
can return to the source material, clarify something, and resume writing.
Do not persist the draft across application restarts, promise a lifetime, or
implement a draft-expiry timer. Application restart clears the draft.
This does not provide durable saving and does not create a capture or delivery
queue entry. Only a successful explicit durable local save does that.

## Resuming and replacing drafts

Fast entry without new material resumes the in-memory draft. If a new Share
action arrives while a draft exists, offer to replace the draft with the new
material or return to the existing draft. Replacement explicitly warns that
the previous input will be discarded; do not automatically merge the inputs.

## Save feedback and return

After successful durable local saving, close the form and briefly confirm
"Saved on this device". Fast capture returns to the originating application;
capture opened from the queue returns to the queue. This feedback concerns local
saving, not delivery; there is no delivery-success notification or history.

## Recording controls

Offer Record, Stop, Listen, and Delete. Show elapsed recording time and the
five-minute limit. Save during recording stops recording and saves the complete
input. Dismissing the form also stops recording and retains it in the in-memory
draft. Deleting a recording permits recording a replacement; do not join
multiple recordings together.

## Queue and errors

Each queue entry shows capture time, optional category, composition (such as
text, recording, and file count), and a short identifying label from the start
of the comment or an available source title. Do not offer full-content viewing
or editing. Show delivery state, an understandable error reason, and appropriate
actions. Uncertain delivery requires explicit owner verification and resolution;
an ordinary retry cannot bypass it.

Initially show delivery problems in the queue without system error
notifications. A local-save failure is shown in the capture form and preserves
input for correction and retry.

## Review and implementation follow-through

The owner accepted quick capture, separate queue access, in-memory drafts,
replacement on incoming share, recording, mixed input, file failures, unavailable
backend, retry, and uncertainty resolution in the disposable sketch. Subsequent
discussion approved exact selected passages with source context across all
platforms and nonblocking optional completion of missing titles or links. The
sketch was updated to reflect those refinements. This review validates the
proposed interaction, not actual platform integration, source payload
availability, or durable storage. Existing lifecycle,
attachment, delivery, and speech policies remain the constraints on the sketch.

The disposable sketch is archived on the local-only branch
`research/issue-9-interaction`, commit `eea12ba`, at
`prototypes/issue-9-interaction.prototype.html`. It is intentionally excluded
from the main branch. Extract a standalone copy with:

```sh
git show research/issue-9-interaction:prototypes/issue-9-interaction.prototype.html > /tmp/idea-capture-interaction.html
```

Its platform selector illustrates the shared behavior; it does not prove native
entry-point support. Carry source-intake checks and real-device capture,
recording, return-to-source, and recovery checks into the relevant stage gates
in issue #11. Platform packaging and implementation choices belong to issue #10.
