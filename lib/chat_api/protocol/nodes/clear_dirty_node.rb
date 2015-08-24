#require 'chat_api/protocol/nodes/protocol_node'
require 'chat_api/protocol/nodes/iq_node'

module Dora
  module Protocol
    class ClearDirtyNode < IqNode

      def initialize(id, categories)
        cat_nodes = []
        categories.each do | category |
          cat_node = ProtocolNode.new('clean', {type: category})
          cat_nodes << cat_node
        end
        super(id, nil, 'set', 'urn:xmpp:whatsapp:dirty', cat_nodes)
      end

    end
  end
end