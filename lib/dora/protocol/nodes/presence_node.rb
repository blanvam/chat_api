require 'dora/protocol/nodes/node'

module Dora
  module Protocol
    module Nodes
      class PresenceNode < Node

        def initialize(attributes)
          super('presence', attributes)
        end

      end
    end
  end
end