require 'dora/protocol/nodes'
require 'dora/protocol/conn/stanzas'

module Dora
  module Protocol
    module Sender

      include Dora::Protocol::Nodes
      include Dora::Protocol::Stanzas

      def send_message(to, txt, id = nil)
        body_node = Node.new('body', nil, nil, txt)
        send_message_node(to, body_node, id)
      end

      def send_broadcast(targets, node, type)
        targets = [targets] unless targets.is_a?(Array)
        to_nodes = []
        targets.each do | target |
          to_nodes << Node.new('to', {jid: target.to_jid.to_s})
        end

        broadcast_node = Node.new('broadcast', nil, to_nodes)
        message_id = create_msg_id
        message_node = Node.new('message', {to: Time.now.getutc+'@broadcast', type: type, id: message_id}, [node, broadcast_node])
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

      def send_message_node(to, node, id = nil)
        message_id = id.nil? ? create_msg_id : id
        send_node(MessageNode.new(node, to.to_jid.to_s, message_id))
        wait_for_server(message_id)
        message_id
      end

      def send_ping
        ping_node = Node.new('ping')
        iq_node = IqNode.new(create_iq_id, WHATSAPP_SERVER, 'get', 'w:p', [ping_node])
        send_node(iq_node)
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

    end
  end
end