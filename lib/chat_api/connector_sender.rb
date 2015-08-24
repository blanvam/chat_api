require 'chat_api/connection'
require 'chat_api/protocol/bin_tree_node_writer'
require 'chat_api/protocol/bin_tree_node_reader'
require 'chat_api/protocol/jid'

Dir.glob('../lib/chat_api/protocol/nodes/*.rb').each { |file| require file }

module Dora

  class ConnectorSender < Connection
    def initialize
      @iq_counter = 1
      @message_counter = 1
      @bin_trees_nodes = { writer: Dora::Protocol::BinTreeNodeWriter.new, reader: Dora::Protocol::BinTreeNodeReader.new}
      super()
    end

    def server_properties
      child = Dora::Protocol::ProtocolNode.new('props')
      node = Dora::Protocol::IqNode.new(create_iq_id, nil, 'get', 'w', [child])
      send_node(node)
    end

    def client_configuration
      attributes = {platform: WHATSAPP_DEVICE, version: WHATSAPP_VER}
      child = Dora::Protocol::ProtocolNode.new('config', attributes)
      node = Dora::Protocol::IqNode.new(create_iq_id, nil, 'set', 'urn:xmpp:whatsapp:push', [child])
      send_node(node)
    end

    def presence_subscription(to)
      send_node(Dora::Protocol::PresenceNode.new({type: 'subscribe', to: to.to_jid.to_s}))
    end

    def send_message(to, txt, id = nil)
      body_node = Dora::Protocol::ProtocolNode.new('body', nil, nil, txt)
      send_message_node(to, body_node, id)
    end

    def synchronize(numbers, deleted_numbers = nil, sync_type = 4, index = 0, last = true)
      child = Dora::Protocol::SyncNode.new(numbers, deleted_numbers, sync_type, index, last)
      id = create_iq_id
      puts "synchronize: #{id}"
      node = Dora::Protocol::IqNode.new(id, nil, 'get', 'urn:xmpp:whatsapp:sync', [child])
      send_node(node)
      wait_for_server(id)
      id
    end

    def send_broadcast(targets, node, type)
      targets = [targets] unless targets.is_a?(Array)
      to_nodes = []
      targets.each do | target |
        to_nodes << Dora::Protocol::ProtocolNode.new('to', {jid: target.to_jid.to_s})
      end

      broadcast_node = Dora::Protocol::ProtocolNode.new('broadcast', nil, to_nodes)
      message_id = create_msg_id
      message_node = Dora::Protocol::ProtocolNode.new('message', {to: Time.now.getutc+'@broadcast', type: type, id: message_id}, [node, broadcast_node])
      send_node(message_node)
      wait_for_server(message_id)
      message_id
    end

    protected

    def writer
      @bin_trees_nodes[:writer]
    end

    def reader
      @bin_trees_nodes[:reader]
    end

    def create_iq_id
      iq_id = @iq_counter
      @iq_counter += 1
      iq_id.to_s(16)
    end

    def create_msg_id
      message_id = @message_counter
      @message_counter += 1
      @login_time.to_i.to_s + '-' + message_id.to_s
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

    def send_ack(node, cla)
      send_node(Dora::Protocol::AckNode.new(node, cla))
    end

    def send_iq_ack(node)
      ack_node = Dora::Protocol::AckNode.new(node)
      iq_node = Dora::Protocol::IqNode.new(create_iq_id, nil, 'set', 'w:m', [ack_node])
      send_node(iq_node)
    end

    def send_receipt(node, type = 'read', participant = nil, call_id = nil)
      send_node(Dora::Protocol::ReceiptNode.new(node, type, participant, call_id))
    end

    def send_clear_dirty(categories)
      send_node(Dora::Protocol::ClearDirtyNode.new(create_iq_id, categories))
    end

    def send_presence(attributes)
      send_node(Dora::Protocol::PresenceNode.new(attributes))
    end

    private

    def send_node(node, encrypt = true)
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