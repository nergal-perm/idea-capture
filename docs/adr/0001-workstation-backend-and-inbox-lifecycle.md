# Use the owner's workstation and the existing Inbox lifecycle

Run the shared capture backend on the owner's existing workstation as an
unprivileged user service started after login, writing notes to the existing
local Inbox and using the vault's existing synchronization. Client queues
absorb periods when the machine is asleep or off; independent server
availability and automatic failover are not required. This favors existing
resources and simple owner-operated deployment over a dedicated always-on host.

Tailscale owns device authorization and revocation; the application does not
introduce a separate client-key lifecycle. Restrict backend writes to its Inbox
and service directories, with the enforcement mechanism chosen during
implementation.

For early stages, omit a dedicated capture backup system and accept possible
loss of unprocessed material after server storage loss. Once processed,
retained material follows the vault's storage and backup rules. Durable saving,
retries, and service recovery after ordinary restarts remain required; a
short-lived Inbox does not imply automatic expiry of captures or retry identity.
