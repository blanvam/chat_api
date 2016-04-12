require 'dora/process_node'

require 'dora/errors'
require 'dora/util'

require 'dora/protocol/identifiers'
require 'dora/protocol/conn/sender'

module Dora
  class Connector

    module Protocol
      module Auth
        autoload :Authentication,   'dora/protocol/auth/authentication'
      end

      module Nodes
        autoload :AckNode,          'dora/protocol/nodes/ack_node'
        autoload :AuthNode,         'dora/protocol/nodes/auth_node'
        autoload :AuthResponseNode, 'dora/protocol/nodes/auth_response_node'
        autoload :ClearDirtyNode,   'dora/protocol/nodes/clear_dirty_node'
        autoload :FeatureNode,      'dora/protocol/nodes/features_node'
        autoload :IqNode,           'dora/protocol/nodes/iq_node'
        autoload :MessageNode,      'dora/protocol/nodes/message_node'
        autoload :PresenceNode,     'dora/protocol/nodes/presence_node'
        autoload :Node,             'dora/protocol/nodes/node'
        autoload :ReceiptNode,      'dora/protocol/nodes/receipt_node'
        autoload :SyncNode,         'dora/protocol/nodes/sync_node'
      end
    end

    autoload :JID,                'dora/protocol/jid'
    autoload :Connector,          'dora/protocol/connector'

    autoload :WTCPClient,         'dora/net/wtcp_client'

    include Dora::Protocol::Sender
    include Dora::Protocol::Identifiers

    attr_accessor :auth

    def initialize(number)
      @auth = Authentication.new number
      @node_id = {}
    end

    def request_last_seen(to)
      msg_id = @node_id['getlastseen'] = create_iq_id
      query_node = Node.new('query')
      message_node = IqNode.new(msg_id, to.to_jid.to_s, 'get', 'jabber:iq:last', [query_node], '')
      send_node(message_node)
      wait_for_server(msg_id)
    end

    def server_properties
      child = Node.new('props')
      node = IqNode.new(create_iq_id, nil, 'get', 'w', [child])
      send_node(node)
    end

    def client_configuration
      attributes = {platform: WHATSAPP_DEVICE, version: WHATSAPP_VER}
      child = Node.new('config', attributes)
      node = IqNode.new(create_iq_id, nil, 'set', 'urn:xmpp:whatsapp:push', [child])
      send_node(node)
    end

    def presence_subscription(to)
      send_node(PresenceNode.new({type: 'subscribe', to: to.to_jid.to_s}))
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

    private

    def wait_for_server(id, timeout = 5)
      server_received_id = ''
      time = Time.now
      begin
        node = poll_message
        server_received_id = node.attributes['id'] unless node.nil?
      end while server_received_id != id && Time.now - time < timeout
    end

  end
end