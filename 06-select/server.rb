#!/usr/bin/ruby
# frozen_string_literal: true

require 'pg'
require 'socket'
require 'fcntl'

port = (ENV['PORT'] || '4444').to_i
host = ENV['HOST'] || '127.0.0.1'

File.open('server.port', 'w') { |file| file.write(port) }
File.open('server.pid', 'w') { |file| file.write(Process.pid) }

server_socket = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM)
server_socket.setsockopt(:SOCKET, :REUSEADDR, true)
server_socket.bind(Socket.sockaddr_in(port, host))
server_socket.listen(2048)

warn "[server] listening: host=#{host}, port=#{port}"

conn = PG.connect('postgresql://ruby:ruby@localhost:5432/ruby-concurrency')

sockets = [server_socket]

loop do
  readable, = IO.select(sockets)

  readable.each do |socket|
    if socket == server_socket
      # handle inbound TCP connection attempt
      client_socket, = socket.accept
      sockets << client_socket
    else
      # ready to read from TCP connection
      request_line = socket.readline.chomp
      socket.write <<~RES.chomp
        HTTP/1.1 200 OK
        Content-Length: #{request_line.length}
        Connection: close
        Content-Type: text/plain

        #{request_line}
      RES

      conn.exec_params('INSERT INTO request_log (url) VALUES ($1)', [request_line])

      socket.close
      sockets.delete(socket)
    end
  end
end
