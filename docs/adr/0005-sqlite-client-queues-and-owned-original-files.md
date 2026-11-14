# Use SQLite client queues with separately owned original files

Owner-confirmed [resolution of #10](https://github.com/nergal-perm/idea-capture/issues/10#issuecomment-6883781978).

Use SQLite for all client queues, recording immutable capture descriptions,
delivery states and retry scheduling, while retaining original attachments as
separate client-owned files until confirmed delivery. This gives clients one
storage model for querying and recovery without placing potentially large
originals inside the database. Share the client schema, queries and migrations,
using platform drivers; the backend has its own schema. Exact drivers and SQL
tooling remain implementation choices validated by the early compatibility build.

A desktop client service is the sole owner of its queue and files; UI accesses
them through the service protocol. SQLite commits do not atomically commit
external file operations, so local save, staging recovery and delivered-data
cleanup must follow explicit ordering and recovery rules. The existing
uncertain-publication policy for the backend remains unchanged.
