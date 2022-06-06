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

[1]: https://httpd.apache.org/docs/2.4/programs/ab.html

### Running Things

Make sure that you've installed Docker for Mac and that the daemon is alive and
well. You'll also need Docker Compose, which is bundled with Docker. Once those
are installed, bring up the PostgreSQL database used by the examples:

```shell
17:44 $ docker-compose -f ./docker-compose.yml down ; docker-compose -f ./docker-compose.yml up --remove-orphans --detach
```

Then, run any one of the Makefile targets:

```shell
17:50 $ make fourth
bundle
Using bundler 2.2.32
Using pg 1.3.5
Bundle complete! 1 Gemfile dependency, 2 gems now installed.
Use `bundle info [gemname]` to see where a bundled gem is installed.
CREATE TABLE
CONCURRENCY=100 NUM_REQUESTS=3000 SERVER=04-threads ./load-test.sh
[load test] waiting for HTTP server to come online...
[server] listening: host=127.0.0.1, port=60535
[load test] starting: protocol=http, host=127.0.0.1, port=60535, concurrency=100, num_requests=3000
This is ApacheBench, Version 2.3 <$Revision: 1879490 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking 127.0.0.1 (be patient)
Completed 300 requests
Completed 600 requests
Completed 900 requests
Completed 1200 requests
Completed 1500 requests
Completed 1800 requests
Completed 2100 requests
Completed 2400 requests
Completed 2700 requests
Completed 3000 requests
Finished 3000 requests


Server Software:
Server Hostname:        127.0.0.1
Server Port:            60535

Document Path:          /
Document Length:        14 bytes

Concurrency Level:      100
Time taken for tests:   3.907 seconds
Complete requests:      3000
Failed requests:        0
Total transferred:      279000 bytes
HTML transferred:       42000 bytes
Requests per second:    767.88 [#/sec] (mean)
Time per request:       130.228 [ms] (mean)
Time per request:       1.302 [ms] (mean, across all concurrent requests)
Transfer rate:          69.74 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    0   0.4      0       3
Processing:     1  128  17.2    131     142
Waiting:        0  128  17.2    131     141
Total:          4  128  16.9    131     142

Percentage of the requests served within a certain time (ms)
  50%    131
  66%    132
  75%    134
  80%    134
  90%    137
  95%    138
  98%    140
  99%    141
 100%    142 (longest request)
[load test] cleaning up...
#inputs: 6005, #outputs: 6007, max mem: 21660K
```