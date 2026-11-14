# Recorded comments and transcription

Owner-approved decisions from the completed design discussion for
[issue #8](https://github.com/nergal-perm/idea-capture/issues/8).
Recognition selection and implementation-stage follow-through are listed below.
Delivery and original-audio retention follow the [delivery contract](delivery.md)
and [attachment policy](attachments.md).

## Languages and recording length

Support Russian, English, and speech mixing both languages without manual
language switching, including English terms and names inside Russian speech.
A typical recording is up to one minute. Initially impose a hard limit of five
minutes per recording. At the limit, stop recording, preserve what has been
recorded, and clearly explain that the limit was reached. The recording still
requires the normal successful durable local save before becoming a capture.

## Comment composition and text fidelity

One comment may combine typed text and one speech recording. Preserve typed
text verbatim and add the transcription separately, without automatically
merging or rewriting the two parts.

Produce text as close as possible to what was said, with punctuation. Do not
summarize, paraphrase, shorten, or apply literary editing. Later summarization
and interpretation belong to note processing outside Idea Capture.

Evaluate quality on a small set of the owner's real recordings: the text should
let the owner recover the thought without mandatory playback and should not
distort its meaning. Pay particular attention to negation, numbers, and names.
The preserved original audio remains available for checking uncertain passages.
The evaluation set and operational acceptance procedure remain to be defined.

## Waiting time and recognition options

Aim to add the transcription within five minutes after delivery when the backend
is available and otherwise idle. This is a measurement target, not a deadline
guarantee. Ordinary desktop work takes priority; recognition may wait longer
under load and must not delay delivery of new captures.

Local and third-party recognition are both acceptable. Privacy is not a gating
criterion for the owner's selection of an external service. No provider or
model has been selected. New expenses remain subject to the separate approval
required by the [server placement decision](adr/0001-workstation-backend-and-inbox-lifecycle.md).

## Backlog and failures

Keep pending transcription tasks without age-based expiry. A backlog may
increase waiting time; one failed recording must not prevent others from being
processed. Ordinary desktop work and delivery of new captures take priority
over recognition.

Automatically make bounded retries after transient recognition failures. Choose
attempt counts and intervals during implementation. When retries are exhausted
or a failure is final, describe it in the note and end the task, retaining the
original audio. Do not restart client delivery or automatically retry after a
final error has been recorded.

When no speech is detected or recognition is impossible, describe that outcome
clearly in the note. If only part of the speech can be recognized, retain useful
text and indicate unintelligible passages without inventing missing words.
Verify support for indicating such passages when evaluating recognition options.

## Follow-through before the speech stage

Select the recognition approach, provider or model, and obtain separate approval
for any new expenses. Evaluate quality and waiting time against the agreed
criteria using a small set of the owner's recordings. Define the concrete
evaluation set, acceptance procedure, retry counts and intervals, and technical
scheduling parameters before implementing the affected behavior. Perform
focused research or measurements once candidates and questions are specific,
following the progressive elaboration agreed in
[the coarse route](https://github.com/nergal-perm/idea-capture/issues/12#issuecomment-6855308010).
These details must respect the already agreed post-delivery lifecycle and safe
note updates.
