require 'chat_api/connector_media'
require 'chat_api/process_node'
require 'chat_api/protocol/challenge'
require 'chat_api/protocol/key_stream'

require 'chat_api/errors'
require 'chat_api/util'

module Dora

  class Connector < ConnectorMedia
    def initialize(number)
      @challenge = Dora::Protocol::Challenge.new(number)
      @keys = { input: nil, output: nil}
      @nodes = []
      @messages = []
      @timeout = nil
      @v1O_only = []
      #@last_id == nil
      #@out_queue = []
      @bind = ProcessNode
      super()
    end

    def get_messages
      @messages
    end

    def reset_messages
      @messages = []
    end

    def get_nodes
      @nodes
    end

    def reset_nodes
      @nodes = []
    end

    def poll_message
      raise ChatAPIError.new('Connection Closed!') unless connected?

      stanza = read_stanza
      if stanza
        @timeout = nil
        process_stanza(stanza)
      else
        if @timeout.nil?
          @timeout = Time.now
        end
        if (Time.now - @timeout) > 300
          @timeout = nil
          disconnect
          raise ChatAPIError.new('Connectivity error')
        end
        nil
      end
    end

    def do_login(password)
      return true if logged?

      writer.reset_key
      reader.reset_key
      resource = "#{PLATFORM}-#{WHATSAPP_VER}"

      send_data(writer.start_stream(WHATSAPP_SERVER, resource))
      send_node(Dora::Protocol::FeatureNode.new)
      send_node(Dora::Protocol::AuthNode.new(@challenge.id, create_authentication(password)))

      poll_message
      poll_message
      poll_message

      unless @challenge.data.nil?
        send_node(Dora::Protocol::AuthResponseNode.new(authenticate(password)))
        reader.set_key(@keys[:input])
        writer.set_key(@keys[:output])
        until poll_message do 1 end
      end

      raise ChatAPIError.new('Login failure') unless logged?

      Base64.strict_decode64(password)

      set_message_id(Digest::SHA1.hexdigest("--#{rand(10000)}--#{Time.now}--")[0,12])

      true
    end

    def set_bind(bind) #1974
      @bind = bind
    end

    private

    def process_stanza(data)
      logger.debug_log('Received: '+bin2hex(data)+"\n")
      node = reader.next_tree(data)
      process_stanza_node(node)
      node
    end

    def process_stanza_node(node, auto_receipt = true, type = 'read')
      @nodes << node
      @timeout = Time.now
      @server_received_id = node.attributes['id']
      logger.debug_log(node.to_s('rx ')+"\n")
      case node.tag
        when 'start', 'stream:features', 'ack', 'chatstate', 'from'
        when 'challenge'
          @challenge.data = node.data
        when 'failure'
          log_out
          if node.children.first.tag == 'not-authorized'
            logger.error('Blocked number or wrong password.')
          end
        when 'success'
          if node.attributes['status'] == 'active'
            log_in
            @challenge.write_data = node.data
            writer.set_key(@keys[:output])
          elsif node.attributes['status'] == 'expired'
          end
        when 'stream:error'
          # Disconnect socket on stream error.
          disconnect
        when 'receipt'
          if node.child? 'retry'
            send_get_cipher_keys_grom_user(JID.new(node.attributes('from')).number, true)
            #@message_store.set_pending(node.attributes['id'], node.attributes['from'])
          end
          if node.child?('error') && node.get_child('error').attributes['type'] == 'enc-v1'
            @v1O_only[ExtractNumber(node.attributes['from'])] = true
            #@message_store.set_pending(node.attributes['id'], node.attributes['from']
            send_pending_messages node.attributes['from']
          end
          send_ack(node, node.tag)
        when 'notification'
          send_ack(node, node.tag)
        when 'call'
          if node.get_child(0).tag == 'offer'
            call_id = node.get_child(0).attributes['call-id']
            send_receipt(node, nil, nil, call_id)
          else
            send_ack(node, 'call')
          end
        when 'message'
          @messages << node
          #send_next_message if node.child?('x') && @last_id == node.attributes['id']
          if node.attributes['type'] == 'text' && !node.get_child('body').nil?
            author = node.attributes['participant']
            send_receipt(node, type, author) if auto_receipt
            if author == ''
              #private chat message
              #@message_store.save_message(extract_number(node.attributes('from')), @phone_number, node.get_child('body').data, node.attributes['id'], node.attributes['t']) unless @message_store.nil?
            else
              #group chat message
              #@message_store.save_message(author, node.attributes['from'], node.get_child('body').data, node.attributes['id'], node.attributes['t']) unless @message_store.nil?
            end
          end
          if node.attributes['type'] == 'media' && !node.get_child('media').nil?
            if node.get_child('media').attributes['type'] == 'image'
              send_iq_ack(node)
            end
            send_receipt(node, type) if auto_receipt
          end
          send_receipt(node, type) if auto_receipt && node.attributes['type'] == 'text' && node.get_child(0).tag == 'enc'
        when 'ib'
          node.children.each do | child |
            case child.tag
              when 'dirty'
                send_clear_dirty([child.attributes['type']])
              when 'account', 'offline'
              else
                raise ChatAPIError.new("ib handler for #{child.tag} not implemented")
            end
          end
        when 'presence'
          if node.attributes['status'] == 'dirty'
            #clear dirty
            categories = []
            if node.children.length > 0
              node.children.each do | child|
                if child.tag == 'category'
                  categories << child.attributes('name')
                end
              end
            end
            send_clear_dirty(categories)
          end
        when 'iq'
          if node.attributes['type'] == 'get' && node.attributes['xmlns'] == 'urn:xmpp:ping'
            send_pong(node.attributes['id'])
          end
          if node.attributes['type'] == 'result' && ( !node.get_child('media').nil? || !node.get_child('duplicate').nil? )
            process_upload_response(node, @challenge.id)
          end
        else
          raise ChatAPIError.new("tag: '#{node.tag}' not implemented")
      end
      @bind.process(node)
      node
    end

=begin
    def send_next_message
      if @out_queue.length > 0
        message_node = @out_queue.shift
        message_node.refresh_times
        @last_id = message_node.attributes['id']
        send_node(message_node)
      else
        @last_id = nil
      end
    end
=end

    def create_authentication(password)
      unless @challenge.data.nil?
        key = OpenSSL::PKCS5.pbkdf2_hmac_sha1(Base64.strict_decode64(password), @challenge.data, 16, 20)
        @keys[:input] = Dora::Protocol::KeyStream.new(key[2], key[3])
        @keys[:output] = Dora::Protocol::KeyStream.new(key[0], key[1])
        reader.set_key(@keys[:input])
        array = "\0\0\0\0#{@challenge.id}#{@challenge.data}1453420825" #{Time.now.getutc.to_i.to_s}"
        @challenge.data= nil
        return @keys[:output].encode_message(array, 0, array.length, 0)
      end
      nil
    end

    def authenticate(password)
      keys = Dora::Protocol::KeyStream.generate_keys(Base64.strict_decode64(password), @challenge.data.clone)
      @keys[:input] = Dora::Protocol::KeyStream.new(keys[2], keys[3])
      @keys[:output] = Dora::Protocol::KeyStream.new(keys[0], keys[1])
      array = "\0\0\0\0#{@challenge.id.force_encoding(BINARY_ENCODING)}#{@challenge.data}#{Time.now.getutc.to_i.to_s}" + '000' +
          hex2bin('00') + '000' + hex2bin('00') + OS_VERSION + hex2bin('00') + MANUFACTURER + hex2bin('00') + DEVICE + hex2bin('00') + BUILD_VERSION
      @keys[:output].encode_message(array, 0, 4, (array.length - 4))
    end

  end
end