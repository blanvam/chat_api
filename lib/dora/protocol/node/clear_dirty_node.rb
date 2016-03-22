require 'dora/protocol/node/iq_node'

module Dora
  module Protocol
    module Node
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
end