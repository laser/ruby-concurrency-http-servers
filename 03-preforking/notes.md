# Preforking

The threaded web server creates a fixed-sized pool of processes and
relies on the kernel to distribute inbound TCP connections amongst
them.

## Miscellaneous

1. Need to pre-determine proper worker pool-size
2. No shared heap means that you can't easily share state, e.g.
   database connection