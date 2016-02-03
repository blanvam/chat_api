require 'chat_api/net/wtcp_socket'

module Dora
  class Connection

    def initialize
      @status = :disconnected
      @socket = nil
    end

    def connect
      @socket = Dora::Net::WTCPSocket.new('e' + rand(1..16).to_s + '.whatsapp.net', PORT, TIMEOUT_SEC, TIMEOUT_SEC)
    end

    def connected?
      @socket.connected?
    end

    def log_in
      @status = :connected
    end

    def log_out
      @status = :disconnected
    end

    def logged?
      connected? && @status == :connected
    end

    def disconnect
      unless @socket.nil?
        @socket.close
        @status =:disconnect
      end
    end

    protected

    def send_data(data)
      logger.debug_log('Sent: '+bin2hex(data)+"\n")
      unless @socket.nil?
        begin
          @socket.write(data)
        rescue Errno::EPIPE
          STDERR.puts 'Connection broke!'
          disconnect
          raise ChatAPIError.new('Connection Closed!')
        end
      end
    end

    def read_stanza
      buffer = ''.force_encoding(BINARY_ENCODING)
      unless @socket.nil?
        header = ''.force_encoding(BINARY_ENCODING)
        buff = ''.force_encoding(BINARY_ENCODING)
        begin
          @socket.read(3, header)
        rescue SocketTimeout
          #STDERR.puts 'Exceeded time.'
        end
        unless header
          @socket.close
        end

        if header.length == 0
          #no data received
          return nil
        end
        if header.length != 3
          raise ChatAPIError.new('Failed to read stanza header')
        end
        tree_length = (header[0].ord & 0x0F) << 16 | header[1].ord << 8 | header[2].ord << 0

        begin
          @socket.read(tree_length, buff)
        rescue SocketTimeout
          #STDERR.puts 'Exceeded time.'
        end
        len = buff.length
        while buff.length < tree_length
          to_read = tree_length - buff.length
          begin
            message = ''.force_encoding(BINARY_ENCODING)
            @socket.read(to_read, message)
          rescue SocketTimeout
            #STDERR.puts 'Exceeded time.'
          end
          buff += message
          if len == buff.length
            #no new data read, fuck it
            break
          end
          len = buff.length
        end

        if buff.length != tree_length
          raise ChatAPIError.new("Tree length did not match received length (buff = #{buff.length} & tree_length = #{tree_length})")
        end
        buffer << header << buff
      end
      buffer
    end

  end
end