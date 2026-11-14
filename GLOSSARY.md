# Idea Capture

The language of capturing source material and original thoughts for later processing in an Inbox.

## Language

**Capture draft**:
Unsubmitted input in the capture form, retained in memory when the form is dismissed so the author can return to it. It is not a saved capture, has no guaranteed lifetime or application-managed expiry, and is cleared when the application restarts.
_Avoid_: Saved capture (for unsubmitted input)

**Capture**:
A single saved submission containing up to one source-material block, up to one original comment, and any attachments, with at least one part present. Its parts belong together and produce one fleeting note.
_Avoid_: Note (before delivery)

**Category**:
An optional classification of a capture as a task, event, fact, emotion, idea, or question. A capture has at most one category, applying to the whole capture.

**Capture time**:
The time a capture is saved on its originating device, including that device's local date and UTC offset, also treated as the time its thought arose. There is no separately assigned thought date or context date.
_Avoid_: Context date (as a separate date)

**Source material**:
Text, including an exact selected passage, a link, and available identifying context for material from another application, with context supplied by the source or the author. It remains distinguishable from the author's own comment.
_Avoid_: Comment

**Comment**:
The author's own thought accompanying source material or attachments, or submitted on its own. One comment may combine typed text and one speech recording; the typed text and transcription remain distinguishable.
_Avoid_: Source material

**Transcription**:
A rendering of a recorded comment as text, staying as close as possible to what was said. Summarization, paraphrasing, and later interpretation belong to note processing outside Idea Capture.
_Avoid_: Summary, paraphrase

**Attachment**:
An original file saved as part of a capture and linked from its resulting fleeting note, including audio supplied as a file rather than recorded as a spoken comment. Preserving a file does not imply extracting or interpreting its content.
_Avoid_: Extracted content

**Fleeting note**:
The temporary Inbox item created from a capture for later processing in PersonalOS. Backend transcription may supplement it after delivery; further vault processing and the fate of its linked originals are outside Idea Capture.
_Avoid_: Capture (for the resulting Inbox item)

**Delivered**:
The outcome in which creation of the resulting fleeting note in the backend's copy of the vault, with all of its original files preserved and linked, has been confirmed. A recorded comment is delivered through its preserved audio link; transcription may follow later.
_Avoid_: Sent, uploaded (as synonyms for delivered)

**Uncertain delivery**:
A capture outcome in which it cannot be established whether the fleeting note was created before an interruption. It requires explicit owner resolution before delivery can be confirmed or publication attempted again.
_Avoid_: Failed delivery (when the outcome is unknown)
