# Implementation roadmap

Owner-approved implementation roadmap for
[issue #11](https://github.com/nergal-perm/idea-capture/issues/11).
The owner accepted the consolidated document after the design discussion.
Acceptance selects the plan; it does not authorize implementation or deployment.
No calendar dates are set. Deferred technical choices have explicit deadlines
below.

## Accepted route

The owner-approved order from
[issue #12](https://github.com/nergal-perm/idea-capture/issues/12#issuecomment-6855308010)
is:

1. Shared client core/backend and text-only Omarchy end-to-end capture.
2. Original attachments, including support in Omarchy.
3. Backend-coordinated speech, including recording in Omarchy.
4. Android with the complete capability set.
5. macOS with the complete capability set.
6. Whole-system acceptance against the real backend and Inbox.

Read the later lifecycle, delivery, speech, interaction and technology decisions
alongside that route. In particular, confirmed delivery silently removes client
data; recognition may use a third-party service; delivery precedes recognition.
These later decisions refine the wording of the original coarse route.

Operational readiness belongs to every stage. Resolve detailed choices before
implementing the affected behavior, investigating compatibility risks early.
Research evidence does not establish acceptance of production artifacts.

## Scope and acceptance principles

### First-stage text scope

Stage 1 includes direct input and intake of exact selected text from a real
browser and reader on Omarchy. Preserve available identifying source context,
keep source material separate from the author's typed comment, and support an
optional category and the delivery queue. Missing source metadata does not
block saving. Attachments arrive in stage 2; recording arrives in stage 3.

The installed result must replace the current plugin with a usable text capture
tool. Retain the existing installation until the replacement works, following
the [technology boundaries](technology-boundaries.md).

### Evidence and acceptance responsibility

Every stage requires both reproducible technical verification and the owner's
review of the installed result in ordinary use. Automate checks of failures,
retries, integrity and recovery where applicable. Verify source-app entry,
permissions and platform lifecycle on actual devices.

For each acceptance criterion, retain the observed result and a way to repeat
the check. Accept the stage after explicit owner confirmation. Disposable
research prototypes do not substitute for production acceptance.

### Workflow review after stage 1

After practical use of the first end-to-end stage, review the Matt Pocock
workflow trial before proceeding to stage 2:

- Did it deliver a useful result?
- How much owner attention did it require?
- Which decisions required rework?
- Did issues and documents help preserve shared understanding?

Record which working practices to keep, change or remove for the next stage.
There is no preset minimum number of days or captures for this review.

## First-stage execution and separate research

### First-stage work sequence

1. Verify the selected KMP dependencies, Android compilation of the common
   core, Compose and platform SQLite drivers before stabilizing shared modules.
2. Implement durable local saving, the queue and the separate client service;
   verify crash recovery.
3. Integrate the backend: Inbox creation, confirmation, duplicate-free retries
   and explicit uncertain-delivery resolution.
4. Complete the text UI and source-app entry, install the plugin replacement,
   perform stage acceptance and review the workflow trial.

These are internal work steps. Stage 1 is complete only when the whole
installed result is accepted.

### Representative Omarchy sources

Use Chromium and Zotero as the browser and reader for stage-1 acceptance.
Verify exact selected text, available identifying context, a separate comment
and return to the source. Missing title/URL remains visible and can be supplied
manually without blocking save.

### Optional system-wide entry research

The owner clarified that this is research into a possible extension, not a
prerequisite for stage 1. Keep it separate from the required selected-text
intake and do not delay first-stage implementation or acceptance for it.

Research scope:

1. Investigate whether Omarchy already provides a built-in equivalent of a
   Share intent usable as a global entry into Idea Capture, including whether
   it is available from arbitrary applications and what data it supplies.
2. If no suitable mechanism exists, conduct a disposable feasibility spike for
   a custom system-wide entry into Idea Capture. A general Share broker with
   multiple destination applications is outside this investigation.

Distinguish invocation availability from access to selected text, files and
source context. Do not assume that a globally callable action implies those
payloads are available. A global shortcut may provide invocation without
opening Idea Capture in advance. The research must establish actual payload
capabilities and limitations; this record does not claim the mechanism exists
or works. Research completion does not make the extension mandatory product
scope or authorize its production implementation.

### Reinstallation and service recovery

Stage 1 includes reinstalling the same application version while retaining
client queues and backend state. Accumulate captures with the backend
unavailable, stop components, reinstall following the documented procedure,
restart and verify delivery without loss or duplicates.

This checks program recovery with intact stored data, not recovery after
server disk loss. Add real upgrade/migration checks when a subsequent version
exists; do not claim those checks passed on the first release.

## Consolidated stage gates

The sections below assemble the accepted product contracts into the approved
acceptance plan. Approving these gates does not mean the checks have passed.

### Evidence and operations at every stage

For each criterion record the application/build version, relevant platform,
preconditions, repeatable procedure, expected and observed result, and links to
sanitized test output or an owner review. Mark unperformed checks explicitly.
Keep real captures, recordings, live configuration and machine-specific data
outside tracked files. Technical checks must exercise production code and
packaged artifacts; research reports only explain what remains to verify.

At each stage maintain commands for installation, configuration, startup,
status, logs, restart and reinstallation. Verify recovery with stored captures
and receipts intact. Verify applicable upgrades/migrations when a previous
version exists, including failure without silently deleting accepted data.
Document uninstall behavior for retained data. Check background startup and
permissions on the affected platform. Recovery by documented owner/agent
commands within one day is acceptable; dedicated content backup and recovery
after server disk loss are not early-stage gates.

Repeat the earlier checks affected by each change. Stage 6 repeats the complete
cross-platform acceptance set. A failure of a mandatory capability remains an
open gate; change the relevant accepted decision explicitly if necessary.

### Stage 1 — shared mechanism and text-only Omarchy

**Entry:** accepted product contracts and stack; use existing resources and
external configuration. Choose exact build/dependency versions and drivers in
step 1.1. The optional global-entry investigation is not a blocker.

| Work unit | Required result and checks |
| --- | --- |
| 1.1 — Build and compatibility | Establish contracts, common client core, shared storage/UI and platform/backend boundaries. Compile the selected portable core/storage dependency graph for Android with compatible APIs/bytecode before stabilizing it. Build the actual Compose desktop graph and application-owned runtime distribution. Keep desktop JDBC/Netty and OS lifecycle APIs outside common/Android code. |
| 1.2 — Client durability | Implement immutable captures, originating timestamp/offset, category, SQLite queue and recovery, automatic scheduling, errors, retries and cleanup. Check save interruption before/after durable commit, disk-full/permission errors, restart, concurrent submissions and single service ownership. Local HTTP/JSON must provide discovery, access/error handling and no false-save acknowledgment. Closing UI must leave the headless service working. |
| 1.3 — Backend and delivery | Implement Ktor HTTPS through Tailscale, versioned descriptions/status, a separate backend store, publication and permanent receipts. Verify denied unauthorized access, certificate errors, effective write restrictions and the real deployment without the research SSH forward. Test offline/reconnect, service sleep/off periods, restarts, lost responses, concurrent retries, identity conflicts and unsupported versions. Inject crashes before/after publication and receipt; repeat after moving/deleting the note. Test both explicit uncertain-outcome decisions; ordinary retry must not bypass them and other captures must continue. Confirm cleanup without opening UI. |
| 1.4 — Installed text tool | Implement direct entry, selected text from Chromium and Zotero, optional source context/category, separate comment, drafts/replacement, queue/errors and return to source. Verify literal Unicode/multiline input, missing/manual context, distinct identical saves, immutable saved input and capture time across delayed delivery. Install bundled service/UI with shell/menu integration and supervised login startup without UI. Replace the old QML/Python direct-Inbox path only when the replacement works. Perform the reinstallation scenario, owner practical acceptance and workflow review. |

**Exit:** the owner can use the installed text tool with the real backend/Inbox;
the applicable technical gates and owner review pass, and workflow changes for
stage 2 are recorded. Merely compiling or reaching a disposable Inbox is
insufficient.

### Stage 2 — original attachments

**Entry:** stage 1 accepted and workflow review complete. Before implementing
files, specify production streaming, durable database/file ownership and
recovery, safe disk names, transfer staging and cleanup. Preserve the approved
100 MiB/file, 500 MiB/capture and 20-file configurable defaults.

**Acceptance:** Omarchy can save combined source/comment/multiple-file captures
and file-only captures. Verify boundary and over-limit inputs for each limit,
same-name files, arbitrary types, exact original bytes/checksums and relative
links. A failed file must prevent complete save/delivery without discarding
other input. Test disappearing source access, interrupted local copy/upload,
corruption rejection, missing/cleaned staging, retry from the start of an
interrupted file, reuse of completed files, disk-full and permission errors,
concurrent intake/delivery and staging recovery after crashes. All originals
must be owned before local acknowledgment and preserved/linked before note
publication. Verify local cleanup and that backend cleanup never deletes
delivered files. Lowering limits must not invalidate already accepted captures.
Audio supplied as an ordinary attachment must not be transcribed.

**Exit:** installed Omarchy/backend preserve and deliver complete originals;
technical evidence, owner review and updated operating procedures pass.

### Stage 3 — backend-coordinated speech

**Entry:** stage 2 accepted. First perform focused recognition evaluation and
select a provider/model using the owner's recordings; obtain approval for any
new expense. Define the evaluation set/procedure, bounded retry counts and
intervals, scheduling/resource limits and shared audio-file contract before
implementing affected behavior. Validate Omarchy recording, permissions and
durable file ownership. Later platform adapters must meet the same contract.

**Acceptance:** Omarchy offers Record/Stop/Listen/Delete and a timer, supports
typed text plus one recording, stops/preserves at five minutes and correctly
handles Save/dismiss during recording. Delivery preserves audio and confirms
the initial linked note before recognition; killing the client afterwards must
not lose backend transcription work. Verify Russian, English and mixed speech,
negation/numbers/names, no speech, useful partial text and unintelligible
passages. Measure the five-minute idle-backend target and evaluate local load
if local recognition is selected. Test durable backlog/restarts, bounded
transient retries/final errors, independent tasks and priority for desktop work
and new delivery. Replay around note updates, owner edits, moves and deletion:
no duplicate blocks, overwritten edits, followed/recreated notes or reopened
client captures. Original audio has no automatic expiry.

**Exit:** selected recognition meets owner-reviewed quality criteria; recording,
delivery-before-recognition, safe updates and operation pass on the installed
system. Define Android/macOS recording/permission checks for their stages.

### Stage 4 — Android

**Entry:** stage 3 accepted. Recheck the final dependency/API/bytecode graph even
if the stage-1 check passed. Select representative actual browser, reader and
Files sources and document the device/OS test configuration before acceptance.

**Acceptance:** build/install the actual APK with Android storage/transport and
native Share/direct entry, shared capture/queue UI and all text/file/recording
capabilities. Inspect selection versus whole-document payloads, missing source
context and source return on the real device. Verify permissions, temporary
file access and complete durable ownership before acknowledgment. Exercise
offline/reconnect, backend restart/lost responses, automatic scheduling,
WorkManager/background restrictions, process death, force-stop/reopen, reboot
and device power restrictions with pending captures. Verify recovery/cleanup
without claiming an OS-guaranteed delivery deadline; document required owner
actions. Test applicable update/reinstall paths preserving stored data.

**Exit:** the complete capability set is installed and owner-accepted on the
real Android device, with actual lifecycle limitations documented.

### Stage 5 — macOS

**Entry:** stage 4 accepted. Select representative actual browser, reader and
file-provider sources. Validate the chosen Swift Share form, recording and
permission lifetimes, loopback protocol and original-byte handoff before
relying on them. App Group authorization is only relevant if the implemented
architecture uses it.

**Acceptance:** build the target-platform distribution with bundled runtime,
JVM service/Compose UI and Swift extension; sign/notarize and install the
actual artifact. Verify selected-text versus document sharing, metadata,
original files, direct entry, recording and return to source. Source URLs alone
must never qualify as durable original ownership. Exercise user-agent
registration/approval/disablement, headless login startup, login/logout,
cold/warm Share start, independent UI/service lifetime, service/entry-point
crashes, offline delivery, retries, updates/reinstall and uninstall. Test
discovery/access failures without false local-save acknowledgment and document
actions required after service disablement.

**Exit:** the complete capability set is installed and owner-accepted on the
real Mac, including the native Share path and packaged service lifecycle.

### Stage 6 — whole-system acceptance

**Entry:** stages 1–5 accepted; actual client/backend versions and the remaining
acceptance checklist are recorded. No research fixture substitutes for an
installed component.

**Acceptance:** exercise every client's direct and source-app entry against
the real backend and Inbox with text-only, file-only, mixed-file and recorded
comments, with/without categories and source metadata. Recheck complete local
ownership, immutable identity/time, complete linked note creation, silent
cleanup, post-delivery transcription and original integrity. Run captures
from multiple clients while the backend is unavailable; restart/reconnect and
verify independent delivery. Repeat lost-response recovery after note movement
and deletion, publication-before-receipt uncertainty with both explicit owner
resolutions, and affected crash/storage/version/error scenarios. Verify
operations and all still-unperformed reliability checks on the production
implementation. Use controlled fault injection/test storage for destructive
storage checks while preserving real owner data.

**Exit:** the owner confirms the installed whole system and operating
procedures meet the accepted scope. Later vault synchronization and general
note processing are not acceptance responsibilities.

## Requirement traceability

Every row names where a requirement first becomes usable or verified. Stages
4/5 apply the complete capability set to their clients; stage 6 integrates and
repeats it. A later repetition does not defer the first-stage obligation.

| Requirement / authoritative source | First stage / gate | Later verification |
| --- | --- | --- |
| Equal Omarchy/Android/macOS capabilities; one shared backend — README, #12 | 1 text; 2 files; 3 speech | 4, 5, 6 |
| Exact selected text, separate source/comment, available/manual context, missing metadata — capture interaction, #9 | 1.4, Chromium/Zotero | Actual source apps in 4/5; 6 |
| Direct entry, category, fast capture/queue entry, drafts/replacement, source return — capture interaction | 1.4 | 4, 5, 6 |
| Immutable capture, unique identity per save, no content dedup/cancel, device timestamp/offset — capture lifecycle, #5 | 1.2–1.4 | 2–6 as affected |
| Durable local save, no false acknowledgment, retained input on failure — delivery/interaction | 1.2 | Original ownership in 2/3; 4–6 |
| Queue states/errors/retry; no content browser/editor/history or delivery notifications — lifecycle/interaction | 1.2, 1.4 | 4, 5, 6 |
| Permanent receipts, status-first recovery, no duplicate recreation after note processing — delivery, #7 | 1.3 | Files in 2; platforms in 4/5; 6 |
| Uncertain publication and both explicit owner resolutions — delivery | 1.3–1.4 | 4, 5, 6 |
| Independent captures, automatic retries, no age/attempt expiry, background limits — delivery | 1.2–1.3 | 2, 3; device limits in 4/5; 6 |
| HTTPS/Tailscale authorization, certificates, write restrictions, existing Inbox — #4, technology boundaries | 1.3–1.4 | Deployment changes in 2–5; 6 |
| Kotlin/KMP executable core, actual Android compatibility, shared SQLite schema/migrations — #10 | 1.1–1.2 | Actual Android graph in 4; upgrades in affected stages |
| Separate desktop UI/service, single owner, loopback discovery/access/errors, Compose — #10 | 1.1–1.4 | Swift Share integration in 5; 6 |
| Bundled JVM, supervised login startup, actual packages — #10 | 1.1, 1.4 | Android APK in 4; signed Mac package in 5; 6 |
| Multiple arbitrary originals, naming/collisions, relative links, no extraction — attachments, #6 | 2 | Native intake in 4/5; 6 |
| Configurable file/count/total limits; no invalidation/eviction of accepted data — attachments | 2 | 4, 5, 6 |
| Streaming/integrity/interrupted transfers, complete publication, safe staging cleanup — attachments/delivery | 2 | Audio in 3; 4–6 |
| Recorded versus attached audio; typed plus one recording and recording controls/limit — speech/interaction | 2 ordinary audio; 3 recorded comment | 4, 5, 6 |
| RU/EN/mixed faithful recognition and owner quality evaluation — speech, #8 | 3 entry/evaluation and exit | 4/5 recordings; 6 |
| Audio preservation; delivery before durable background recognition — speech/delivery | 3 | 4, 5, 6 |
| Bounded recognition retries, final/no-speech/partial errors, backlog/resource priority — speech | 3 | 6, and affected changes |
| Safe idempotent transcription updates; owner edits/moved/deleted notes — delivery | 3 | 6 |
| Offline/crash/restart/disk-full/concurrency/version checks — delivery, #11 research follow-through | Applicable cases in 1; files in 2; speech in 3 | Actual lifecycle in 4/5; full set in 6 |
| Installation/reinstallation/recovery, upgrade checks, operating commands — #4, #12, interview Q6 | 1.4; updates when prior version exists | Every affected stage; 6 |
| Owner practical acceptance plus repeatable technical evidence — interview Q2 | 1 exit | Every stage exit |
| Workflow trial review and changed working practices — #12, interview Q3 | After 1, before 2 | Apply findings in later work |

The optional global-entry research is intentionally separate from this
mandatory requirement matrix and creates no blocking edge to stage 1.

## Deferred decisions and their deadlines

Progressive elaboration leaves these choices open without silently assuming
their answers. Each belongs in the relevant work unit/task before affected
implementation; reopen #10 and focused research if required compatibility or
native integration fails rather than dropping accepted scope or rewriting
shared functionality independently on each platform.

| Choice | Resolve before |
| --- | --- |
| Exact versions, build wiring, SQL tooling/drivers and module names | Stabilizing shared modules in 1.1 |
| Local discovery/access/error mechanics, durable save/recovery and schema details | Implementing affected storage/protocol in 1.2 |
| Numeric delivery retry/poll scheduling, classification and test configuration | Implementing scheduling in 1.2–1.3 |
| Endpoints, checksums/identity encoding, publication/recovery algorithms, HTTPS and write-boundary enforcement | Implementing affected backend/delivery in 1.3 |
| Installer/service commands, runtime update and data-retention behavior | Installation/acceptance in 1.4, refined per platform |
| Streaming, staging cleanup and external-file consistency details | Affected implementation in 2 |
| Recording format/ownership contract, recognition choice, evaluation set/procedure, bounded retry/resource parameters and expenses | Affected implementation in 3 |
| Actual Android/macOS source apps and device acceptance procedures | Affected native integration/acceptance in 4/5 |
| Detailed tasks for stages 2–6 | Starting the affected stage; earlier for shared-mechanism risks |

No new capture/UI latency guarantee or fixed background-delivery deadline is
implied. Measure behavior on installed artifacts; resolve observed usability
or resource problems with the owner. The optional system-wide entry work has
its own research outcome and no stage-1 deadline.
