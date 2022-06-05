#!/usr/bin/ruby
# frozen_string_literal: true

require 'socket'
require 'securerandom'

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

  begin
    request_uri = client_socket.readline.split(' ')[1]
    response_body = "(#{SecureRandom.hex(10)}) You made an HTTP request to #{request_uri}\r\n"

    sleep 0.01

    response_string = <<~RES.chomp
      HTTP/1.1 200 OK
      Content-Length: #{response_body.length}
      Connection: close
      Content-Type: text/plain

      #{response_body}
    RES

    client_socket.write response_string
  rescue EOFError
  end

  client_socket.close
end
