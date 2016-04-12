require 'dora/protocol/nodes/node'

module Dora
  module Protocol
    module Nodes
      class ReceiptNode < Node

        def initialize(node, type = 'read', participant = nil, call_id = nil)
          message_hash = {to: node.attributes['from'], id: node.attributes['id'] }
          message_hash['type'] = type if type == 'read'
          message_hash['participant'] = participant unless participant.nil?

          if call_id.nil?
            super('receipt', message_hash)
          else
            offer_node = super('offer', {'call-id': call_id})
            super('receipt', message_hash, [offer_node])
          end
        end

      end
    end
  end
end