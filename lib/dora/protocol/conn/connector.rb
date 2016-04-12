require 'dora/client/sender'

module Dora
  class Protocol
    module Connector

      module BinTree
        autoload :NodeReader,  'dora/protocol/bin_tree/node_reader'
        autoload :NodeWriter,  'dora/protocol/bin_tree/node_writer'
      end

      def connect
        wtp_client.connect
      end

      def do_login(password)
        return true if wtp_client.logged?

        writer.reset_key
        reader.reset_key
        resource = "#{PLATFORM}-#{WHATSAPP_VER}"

        wtp_client.send_data(writer.start_stream(WHATSAPP_SERVER, resource))
        send_node(FeatureNode.new)

        input, output = @auth.authentication(password)
        update_reader(input) if input

        send_node(AuthNode.new(@auth.id, output))

        poll_message
        poll_message
        poll_message

        unless @auth.data.nil?
          send_node(AuthResponseNode.new(@auth.authenticate(password)))
          update_reader
          update_writer
          until poll_message do 1 end
        end

        raise ChatAPIError.new('Login failure') unless wtp_client.logged?

        Base64.strict_decode64(password)

        set_message_id(Digest::SHA1.hexdigest("--#{rand(10000)}--#{Time.now}--")[0,12])

        true
      end

      def poll_message
        raise ChatAPIError.new('Connection Closed!') unless wtp_client.connected?

        stanza = wtp_client.read_stanza
        if stanza
          process_stanza(stanza)
        else
          if (Time.now - timeout) > 60
            send_ping
          end
          nil
        end
      end

      def send_node(node, encrypt = true)
        logger.debug_log(node.to_s('tx  ')+"\n")
        wtp_client.send_data(writer.write(node, encrypt))
      end

      private

      def wtp_client
        @wtp_client ||= Dora::Net::WTCPClient.new
      end

      def writer
        @writer ||= NodeWriter.new
      end

      def reader
        @reader ||= NodeReader.new
      end

      def update_writer(value = @auth.key_output)
        writer.set_key(value)
      end

      def update_reader(value = @auth.key_input)
        reader.set_key(value)
      end

      def timeout
        @timeout ||= Time.now
      end

      def process_stanza(data)
        logger.debug_log('Received: '+bin2hex(data)+"\n")
        node = reader.next_tree(data)
        process_node(node)
        node
      end

    end
  end
end
