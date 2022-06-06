# Threads

The threaded web server creates a fixed-sized pool of threads and
relies on the kernel to distribute inbound TCP connections amongst
them.

## Miscellaneous

1. Need to pre-determine proper worker pool-size
2. Easy to share scarce resource betwene threads b/c of shared heap,
   with easy synchronization via mutex