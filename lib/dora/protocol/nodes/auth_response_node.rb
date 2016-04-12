require 'dora/protocol/nodes/node'

module Dora
  module Protocol
    module Nodes
      class AuthResponseNode < Node

        def initialize(auth_data)
          super('response', nil, nil, auth_data)
        end
      end
    end
  end
end
