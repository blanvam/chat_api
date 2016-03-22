require 'dora/connection'
require 'dora/process_node'

require 'dora/protocol'

require 'dora/errors'
require 'dora/util'

module Dora

  class Connector < Connection
    include Protocol

    autoload :Stanza, 'dora/stanza'

    attr_accessor :auth

    def initialize(number)
      @auth = Authentication.new number
      @stanza = Stanza.new self
      @iq_counter = 1
      @message_counter = 1
      @message_id = ''
      @bin_trees_nodes = {writer: BinTreeNodeWriter.new, reader: BinTreeNodeReader.new}
      super()
    end

    def messages
      @stanza.get_messages
    end

    def do_login(password)
      return true if logged?

      writer.reset_key
      reader.reset_key
      resource = "#{PLATFORM}-#{WHATSAPP_VER}"

      send_data(writer.start_stream(WHATSAPP_SERVER, resource))
      send_node(FeatureNode.new)

      input, output = @auth.authentication(password)
      reader.set_key(input) if input

      send_node(AuthNode.new(@auth.id, output))

      poll_message
      poll_message
      poll_message

      unless @auth.data.nil?
        send_node(AuthResponseNode.new(@auth.authenticate(password)))
        reader.set_key(@auth.key_input)
        writer.set_key(@auth.key_output)
        until poll_message do 1 end
      end

      raise ChatAPIError.new('Login failure') unless logged?

      Base64.strict_decode64(password)

      set_message_id(Digest::SHA1.hexdigest("--#{rand(10000)}--#{Time.now}--")[0,12])

      true
    end

    def poll_message
      raise ChatAPIError.new('Connection Closed!') unless connected?

      stanza = read_stanza
      if stanza
        process_stanza(stanza)
      else
        timeout = @stanza.time
        if (Time.now - timeout) > 300
          @stanza.restart
          disconnect
          raise ChatAPIError.new('Connectivity error')
        end
        nil
      end
    end

    def writer
      @bin_trees_nodes[:writer]
    end

    def reader
      @bin_trees_nodes[:reader]
    end

    def set_message_id(msg)
      @message_id = msg
    end

    def request_last_seen(to)
      msg_id = @node_id['getlastseen'] = create_iq_id
      query_node = ProtocolNode.new('query')
      message_node = IqNode.new(msg_id, to.to_jid.to_s, 'get', 'jabber:iq:last', [query_node], '')
      send_node(message_node)
      wait_for_server(msg_id)
    end

    def server_properties
      child = ProtocolNode.new('props')
      node = IqNode.new(create_iq_id, nil, 'get', 'w', [child])
      send_node(node)
    end

    def client_configuration
      attributes = {platform: WHATSAPP_DEVICE, version: WHATSAPP_VER}
      child = ProtocolNode.new('config', attributes)
      node = IqNode.new(create_iq_id, nil, 'set', 'urn:xmpp:whatsapp:push', [child])
      send_node(node)
    end

    def presence_subscription(to)
      send_node(PresenceNode.new({type: 'subscribe', to: to.to_jid.to_s}))
    end

    def send_message(to, txt, id = nil)
      body_node = ProtocolNode.new('body', nil, nil, txt)
      send_message_node(to, body_node, id)
    end

    def synchronize(numbers, deleted_numbers = nil, sync_type = 4, index = 0, last = true)
      child = SyncNode.new(numbers, deleted_numbers, sync_type, index, last)
      id = create_iq_id
      puts "synchronize: #{id}"
      node = IqNode.new(id, nil, 'get', 'urn:xmpp:whatsapp:sync', [child])
      send_node(node)
      wait_for_server(id)
      id
    end

    def send_broadcast(targets, node, type)
      targets = [targets] unless targets.is_a?(Array)
      to_nodes = []
      targets.each do | target |
        to_nodes << ProtocolNode.new('to', {jid: target.to_jid.to_s})
      end

      broadcast_node = ProtocolNode.new('broadcast', nil, to_nodes)
      message_id = create_msg_id
      message_node = ProtocolNode.new('message', {to: Time.now.getutc+'@broadcast', type: type, id: message_id}, [node, broadcast_node])
      send_node(message_node)
      wait_for_server(message_id)
      message_id
    end

    def send_presence(attributes)
      send_node(PresenceNode.new(attributes.merge({type: 'available'})))
    end

    def send_receipt(node, type = 'read', participant = nil, call_id = nil)
      send_node(ReceiptNode.new(node, type, participant, call_id))
    end

    def send_ack(node, cla)
      send_node(AckNode.new(node, cla))
    end

    private

    def process_stanza(data)
      logger.debug_log('Received: '+bin2hex(data)+"\n")
      node = reader.next_tree(data)
      @stanza.process_node(node)
      node
    end

    def create_iq_id
      iq_id = @iq_counter
      @iq_counter += 1
      id = iq_id.to_s(16)
      if id.size % 2 == 1
        id = '0'+ id.size.to_s
      end
      id
    end

    def create_msg_id
      @message_counter += 1
      @message_id + @message_counter.to_s(16)
    end

    def send_message_node(to, node, id = nil)
      message_id = id.nil? ? create_msg_id : id
      send_node(MessageNode.new(node, to.to_jid.to_s, message_id))
      wait_for_server(message_id)
      message_id
    end

    def send_pong(message_id)
      send_node(IqNode.new(message_id, nil, 'result'))
    end

    def send_iq_ack(node)
      ack_node = AckNode.new(node)
      iq_node = IqNode.new(create_iq_id, nil, 'set', 'w:m', [ack_node])
      send_node(iq_node)
    end

    def send_clear_dirty(categories)
      send_node(ClearDirtyNode.new(create_iq_id, categories))
    end

    def send_node(node, encrypt = true)
      logger.debug_log(node.to_s('tx  ')+"\n")
      send_data(writer.write(node, encrypt))
    end

    def wait_for_server(id, timeout = 5)
      server_received_id = ''
      time = Time.now
      begin
        node = poll_message
        server_received_id = node.attributes['id'] unless node.nil?
      end while server_received_id != id && Time.now - time < timeout
      puts "wait_for_server: #{server_received_id}"
    end

  end

end