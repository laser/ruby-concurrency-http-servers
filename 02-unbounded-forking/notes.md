# Multi-process, Unbounded Concurrency

The multi-process web server forks a child process for each
newly-accepted TCP connection.

## Miscellaneous

1. Maximum RSS can grow to be quite large
2. No easy way to share resources, e.g. database connections