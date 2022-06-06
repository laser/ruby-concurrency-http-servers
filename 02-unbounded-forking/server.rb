#!/usr/bin/ruby
# frozen_string_literal: true

require 'pg'
require 'socket'

port = (ENV['PORT'] || '4444').to_i
backlog_len = (ENV['SOCKET_BACKLOG_LEN'] || '128').to_i
host = ENV['HOST'] || '127.0.0.1'

File.open('server.port', 'w') { |file| file.write(port) }
File.open('server.pid', 'w') { |file| file.write(Process.pid) }

server_socket = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM)
server_socket.setsockopt(:SOCKET, :REUSEADDR, true)
server_socket.bind(Socket.sockaddr_in(port, host))
server_socket.listen(backlog_len)

warn "[server] listening: host=#{host}, port=#{port}"

loop do
  client_socket, = server_socket.accept

  Process.fork do
    server_socket.close

    next if client_socket.eof?

    request_line = client_socket.readline.chomp

    client_socket.write <<~RES.chomp
      HTTP/1.1 200 OK
      Content-Length: #{request_line.length}
      Connection: close
      Content-Type: text/plain

      #{request_line}
    RES

    client_socket.close

    conn = PG.connect('postgresql://ruby:ruby@localhost:5432/ruby-concurrency')
    conn.exec_params('INSERT INTO request_log (url) VALUES ($1)', [request_line])

    Process.exit(0)
  end

  client_socket.close
end
