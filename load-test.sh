#!/bin/bash

__host=127.0.0.1
__port=$(ruby -e 'require "socket"; socket = Socket.new(:INET, :STREAM, 0); socket.bind(Addrinfo.tcp("127.0.0.1", 0)); p socket.local_address.ip_port')
__gtime_pid=""

function finish {
  local -i __max_wait=60
  local __server_pid=$(cat ./server.pid)

  echo "[load test] cleaning up..."
  kill $__server_pid || true

  # Force KILL after __max_wait seconds if the process doesn't
  (
    sleep $__max_wait && kill -9 $__server_pid;
    echo "Sent SIGKILL to __server_pid, but process failed to exit within $__max_wait seconds";
  ) & __waiter_server=$!

  # Wait for gtime to exit
  wait $__gtime_pid

  # Kill watchers
  kill $__waiter_server
}

trap finish EXIT

PORT=${__port} HOST=${__host} SOCKET_BACKLOG_LEN=${SOCKET_BACKLOG_LEN} /usr/bin/time -f '#inputs: %r, #outputs: %s, max mem: %MK' ruby ./${SERVER}/server.rb &
__gtime_pid=$!

until netstat -an | grep ${__port} > /dev/null
do
    echo "[load test] waiting for HTTP server to come online..."
    sleep 1
done

echo "[load test] starting: protocol=http, host=${__host}, port=${__port}, concurrency=${CONCURRENCY}, num_requests=${NUM_REQUESTS}" 1>&2
ab -c ${CONCURRENCY} -n ${NUM_REQUESTS} http://${__host}:${__port}/