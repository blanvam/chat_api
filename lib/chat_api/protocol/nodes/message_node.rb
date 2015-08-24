require 'chat_api/protocol/nodes/protocol_node'

module Dora
  module Protocol
    class MessageNode < ProtocolNode

      def initialize(node, to, id)
        attributes = {
            to: to,
            type: (node.tag == 'body') ? 'text' : 'media',
            id: id,
            t: Time.now.getutc.to_i.to_s
        }
        super('message', attributes, [node])
      end

    end
  end
end