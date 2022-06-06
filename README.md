# Various Concurrency Models Used by Ruby HTTP Servers

This repository contains a few examples of how one might implement a network
server in Ruby using the Socket API plus threads and processes, and uses [ab -
the Apache HTTP server benchmarking tool][1] - for load testing.

The examples demonstrate some of the tradeoffs (throughput vs. memory
utilization vs. shared resource contention vs. programmer ease) that a person
might make when writing a network server (or concurrent code in general) in
Ruby.

## Examples

### 01-iterative

This HTTP server creates a TCP socket and loops, blocking on the accept(2)
syscall. It processes inbound TCP connections (HTTP requests) sequentially, i.e.
it has a concurrency of 1. The server uses a single PostgreSQL connection.

### 02-unbound-forking

This HTTP server forks itself each time the server accepts an inbound TCP
connection. Each forked process creates a connection to the database. There is
no upper bound on the number of forked child processes, which can result in
memory errors, can cause the file descriptor limit to be exceeded, and can
overwhelm the PostgreSQL connection limit.

### 03-preforking

This HTTP server forks a fixed number of worker processes upon boot, and relies
on the kernel to distribute load across processes blocked on the `accept(2)`
syscall. Memory utilization and PostgreSQL connections are limited by the size
of the worker process-pool at the expense of overall throughput.

### 04-threads

This HTTP server forks a fixed number of worker threads on boot, and relies on
the kernel to distribute load across process blocked on the `accept(2)` syscall.
Memory utilization is constrained by the fact that all worker threads share
access to a single heap, and a single, synchronized PostgreSQL connection is
sufficient for the lifetime of the program.