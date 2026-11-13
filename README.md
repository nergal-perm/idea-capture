# Idea Capture

A personal tool for capturing source material and original thoughts into a
PersonalOS Inbox.

The agreed target includes native Android, macOS, and Linux (Omarchy) clients,
a durable local queue, delivery over Tailscale, and server-side creation of
fleeting notes in a configured Inbox. Entry points include sharing from other
apps and direct input; comments can be typed or recorded. All three clients
support optional categorization, following the existing Omarchy plugin.
Speech recognition runs within personal infrastructure. Delivery is confirmed
only after the note exists; retries must not create duplicate notes.

All entry points must use a shared backend processing mechanism, including
when a client and the backend run on the same machine. The deployment model
has not been selected.

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

The future Wayfinder map will lead to an agreed specification for the entire
tool and an ordered implementation plan. The product vision will evolve along
the way. Map creation is deferred until infrastructure questions have been
discussed. The stack, exchange protocol, server, and speech recognition
placement have not been selected.

The project will also serve as a trial of Matt Pocock's workflow from
Software Factories for Real Engineers. The trial steps have not been defined.
