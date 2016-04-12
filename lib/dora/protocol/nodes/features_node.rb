require 'dora/protocol/nodes/node'

module Dora
  module Protocol
    module Nodes
      class FeatureNode < Node

        def initialize
          super('stream:features', nil, nil)
        end

      end
    end
  end
end
