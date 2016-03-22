require 'dora/protocol/node/protocol_node'

module Dora
  module Protocol
    module Node
      class PresenceNode < ProtocolNode

        def initialize(attributes)
          super('presence', attributes)
        end

      end
    end
  end
end