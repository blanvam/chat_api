require 'dora/protocol/node/protocol_node'

module Dora
  module Protocol
    module Node
      class AuthResponseNode < ProtocolNode

        def initialize(auth_data)
          super('response', nil, nil, auth_data)
        end
      end
    end
  end
end
