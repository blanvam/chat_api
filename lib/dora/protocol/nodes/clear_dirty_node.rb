require 'dora/protocol/nodes/iq_node'

module Dora
  module Protocol
    module Nodes
      class ClearDirtyNode < IqNode

        def initialize(id, categories)
          cat_nodes = []
          categories.each do | category |
            cat_node = Node.new('clean', {type: category})
            cat_nodes << cat_node
          end
          super(id, nil, 'set', 'urn:xmpp:whatsapp:dirty', cat_nodes)
        end
      end
    end
  end
end