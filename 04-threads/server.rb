#!/usr/bin/ruby
# frozen_string_literal: true

require 'pg'
require 'socket'

port = (ENV['PORT'] || '4444').to_i
host = ENV['HOST'] || '127.0.0.1'

File.open('server.port', 'w') { |file| file.write(port) }
File.open('server.pid', 'w') { |file| file.write(Process.pid) }

server_socket = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM)
server_socket.setsockopt(:SOCKET, :REUSEADDR, true)
server_socket.bind(Socket.sockaddr_in(port, host))
server_socket.listen(Socket::SOMAXCONN)

warn "[server] listening: host=#{host}, port=#{port}"

conn = PG.connect('postgresql://ruby:ruby@localhost:5432/ruby-concurrency')
conn_mu = Mutex.new

threads = (1..20).map do
  Thread.new do
    loop do
      client_socket, = server_socket.accept

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

      conn_mu.synchronize do
        conn.exec_params('INSERT INTO request_log (url) VALUES ($1)', [request_line])
      end
    end
  end
end

Signal.trap('TERM') do
  threads.each do |thread|
    thread.kill
    thread.join
  end

  Process.exit(0)
end

threads.each do |thread|
  thread.join
end