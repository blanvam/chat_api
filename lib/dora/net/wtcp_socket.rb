# encoding: utf-8
require 'socket'
require 'timeout'

module Dora
  module Net
    class WTCPSocket
      attr_accessor :pid

      def initialize(host, port, operation_timeout = nil, connect_timeout = nil)
        @pid = Process.pid
        @operation_timeout = operation_timeout
        @connect_timeout   = connect_timeout
        @address = TCPSocket.gethostbyname(host)[3]
        @host = host
        @port = port

        connect
      end

      def write(data)
        @socket.write(data)
      end

      def read(maxlen, buffer)
        # Block on data to read for @op_timeout seconds
        begin
          ready = IO.select([@socket], nil, nil, @operation_timeout)

          raise SocketTimeout unless ready
        rescue IOError => ex
          raise ConnectionFailure, ex
        end

        # Read data from socket
        begin
          @socket.sysread(maxlen, buffer)
        rescue SystemCallError, IOError => ex
          raise ConnectionFailure, ex
        end
      end

      def close
        @socket.close
      end

      def closed?
        @socket.closed?
      end

      def connected?
        !@socket.closed?
      end

      private
      def connect
        if @connect_timeout
          Timeout::timeout(@connect_timeout, SocketTimeout) do
            open_socket
          end
        else
          open_socket
        end
      end

      def open_socket
        @socket = TCPSocket.open(@host, @port)
      end
    end
  end
end
