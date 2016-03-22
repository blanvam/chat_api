require 'dora/protocol/node/protocol_node'

module Dora
  module Protocol
    module Node
      class FeatureNode < ProtocolNode

        def initialize
          super('stream:features', nil, nil)
        end

      end
    end
  end
end
