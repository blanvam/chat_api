require 'dora/protocol/bin_tree'
require 'dora/net/wtcp_client'

module Dora
  module Protocol
    class Connection
      include BinTree

      autoload :WTCPClient, 'dora/net/wtcp_client'

      attr_reader :wtp_client, :writer, :reader

      def initialize
        @wtp_client = Dora::Net::WTCPClient.new
        @writer = NodeWriter.new
        @reader = NodeReader.new
      end

      def connect
        @wtp_client.connect
      end

      def logged?
        @wtp_client.logged?
      end

      def send_pre_login(node)
        reset_keys
        send_resource
        send_node(node)
      end

      def poll_message
        raise ChatAPIError.new('Connection Closed!') unless wtp_client.connected?

        stanza = @wtp_client.read_stanza
        if stanza
          parse_stanza(stanza)
        else
          if (Time.now - timeout) > 60
            fail ConnectionTimeout.new('Timeout 60 seconds, must send a ping')
          end
          nil
        end
      end

      def send_node(node, encrypt = true)
        logger.debug_log(node.to_s('tx  ')+"\n")
        @wtp_client.send_data(writer.write(node, encrypt))
      end

      def update_writer(value)
        writer.set_key(value)
      end

      def update_reader(value)
        reader.set_key(value)
      end

      private

      def timeout
        @timeout ||= Time.now
      end

      def parse_stanza(data)
        logger.debug_log('Received: '+bin2hex(data)+"\n")
        reader.next_tree(data)
      end

      def reset_keys
        writer.reset_key
        reader.reset_key
      end

      def send_resource
        resource = "#{PLATFORM}-#{WHATSAPP_VER}"
        @wtp_client.send_data(writer.start_stream(WHATSAPP_SERVER, resource))
      end

    end
  end
end