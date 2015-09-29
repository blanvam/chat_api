require 'chat_api/connector_media'
require 'chat_api/process_node'
require 'chat_api/protocol/challenge'
require 'chat_api/protocol/key_stream'

module Dora

  class Connector < ConnectorMedia
    def initialize(number)
      @challenge = Dora::Protocol::Challenge.new(number)
      @keys = { input: nil, output: nil}
      @nodes = []
      @messages = []
      @timeout = nil
      @login_time = nil
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

    def poll_message(auto_receipt = true, type = 'read')
      raise ChatAPIError.new('Connection Closed!') unless connected?

      stanza = read_stanza
      if stanza
        @timeout = nil
        process_stanza(stanza, auto_receipt, type)
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
      resource = "#{WHATSAPP_DEVICE}-#{WHATSAPP_VER}-#{PORT.to_s}"

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

      @login_time = Time.now.getutc
      true
    end

    def set_bind(bind) #1974
      @bind = bind
    end

    private

    def process_stanza(data, auto_receipt = true, type = 'read')
      node = reader.next_tree(data)
      process_stanza_node(node, auto_receipt, type)
      node
    end

    def process_stanza_node(node, auto_receipt = true, type = 'read')
      @nodes << node
      case node.tag
        when 'start', 'stream:features', 'ack', 'chatstate'
        when 'challenge'
          @challenge.data= node.data
        when 'failure'
          log_out
        when 'success'
          if node.attributes['status'] == 'active'
            log_in
            @challenge.write_data= node.data
            writer.set_key(@keys[:output])
          elsif node.attributes['status'] == 'expired'
          end
        when 'stream:error'
          # Disconnect socket on stream error.
          disconnect
        when 'receipt', 'notification'
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
          #send_next_message if node.has_child?('x') && @last_id == node.attributes['id']
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
          raise ChatAPIError.new("tag: #{node.tag} not implemented")
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
        array = "\0\0\0\0#{@challenge.id.force_encoding(BINARY_ENCODING)}#{@challenge.data}#{Time.now.getutc.to_i.to_s}"
        @challenge.data= nil
        return @keys[:output].encode_message(array, 0, array.length, 0)
      end
      nil
    end

    def authenticate(password)
      keys = Dora::Protocol::KeyStream.generate_keys(Base64.strict_decode64(password), @challenge.data) #clone
      @keys[:input] = Dora::Protocol::KeyStream.new(keys[2], keys[3])
      @keys[:output] = Dora::Protocol::KeyStream.new(keys[0], keys[1])
      array = "\0\0\0\0#{@challenge.id.force_encoding(BINARY_ENCODING)}#{@challenge.data}"
      @keys[:output].encode_message(array, 0, 4, (array.length - 4))
    end

  end
end