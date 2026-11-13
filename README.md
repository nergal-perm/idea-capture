# Idea Capture

A personal tool for capturing source material and original thoughts into a
PersonalOS Inbox.

The agreed target includes native Android, macOS, and Linux (Omarchy) clients,
a durable local queue, delivery over Tailscale, and server-side creation of
fleeting notes in a configured Inbox. Entry points include sharing from other
apps and direct input; comments can be typed or recorded. One capture may combine
source material, multiple arbitrary original file attachments, and a comment,
producing one fleeting note with linked attachments. File-content extraction,
including OCR and PDF text extraction, is outside the agreed scope.
All three clients support optional categorization, following the existing
Omarchy plugin. They prioritize fast capture and provide delivery status and
retry; post-capture content viewing and editing are not required.
Speech processing is coordinated by the shared backend; recognition may run
locally or use a third-party service. The recognition method remains open.
Delivery is confirmed only after the note exists; retries must not create
duplicate notes. Attachment completeness and confirmation semantics remain to
be specified.

All entry points must use a shared backend processing mechanism, including
when a client and the backend run on the same machine. The initial server is
the owner's existing local machine, which may also remain the final host.
Captures wait in client queues while it is asleep or powered off; availability
independently of user workstations is no longer required. The backend starts
after user login and writes into the existing local Inbox, using the existing
vault synchronization. See the
[architecture decision](docs/adr/0001-workstation-backend-and-inbox-lifecycle.md)
and the [server placement and operations resolution](https://github.com/nergal-perm/idea-capture/issues/4)
for the deployment decisions.

## Configuration

Machine-specific paths belong outside the repository in
`$XDG_CONFIG_HOME/idea-capture/config.toml`, falling back to the user's `.config`
directory. Set `CAPTURE_CONFIG` to select another file.
See the [client README](apps/omarchy/README.md) for settings and environment
variables, and [config.example.toml](apps/omarchy/config.example.toml) for neutral
sample values. Keep live configuration, credentials, and captured notes out of
the repository.

## Secret checks before committing

The repository includes a pre-commit hook using `detect-secrets` 1.5.0.
To enable it in a new checkout, install `uv` and run:

```sh
git config --local core.hooksPath .githooks
```

The hook scans the entire Git index, including the staged content of partially
staged files. Potential secrets and scanner failures block the commit.
Diagnostics include only the filename, line number, and finding type.
Two reviewed synthetic request IDs in tests have inline
`pragma: allowlist secret` annotations. On its first run, `uv` downloads the
pinned dependency; subsequent runs use its cache.
Run the check manually without creating a commit:

```sh
git hook run pre-commit
```

## Current state

The existing `eugene.daily-capture` Omarchy plugin, tests, and technical notes
have moved into [apps/omarchy](apps/omarchy/README.md). It retains its current
behavior: text input, an optional category, and direct Inbox writes with
background title generation. Shared backend integration, voice input, a
durable queue, and the other clients remain future work.

See the [plugin README](apps/omarchy/README.md) for installation and validation.

The [Wayfinder map](https://github.com/nergal-perm/idea-capture/issues/1) tracks
the decisions leading to an agreed specification for the entire tool and an
ordered implementation plan. The product vision can evolve along the way.
The stack, exchange protocol, attachment policies, and speech pipeline
remain open decisions. See [GLOSSARY.md](GLOSSARY.md) for domain terminology.

The first implementation stage will be text-only capture through Omarchy,
durable local saving, shared backend processing, Inbox creation, and confirmed
delivery. Attachments, server-side voice, Android, and macOS remain required
later stages; their order and acceptance gates will be decided through the map.

The project will also serve as a trial of Matt Pocock's workflow from
Software Factories for Real Engineers. The trial includes a workflow review
after the first end-to-end stage; its evaluation criteria will be specified in
the roadmap.
