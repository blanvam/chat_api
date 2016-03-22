require 'dora/protocol/node/protocol_node'

module Dora
  module Protocol
    module Node
      class AuthNode < ProtocolNode

        def initialize(number, auth_data)
          super('auth', {user: number, mechanism: 'WAUTH-2'}, nil, auth_data)
        end

      end
    end
  end
end

