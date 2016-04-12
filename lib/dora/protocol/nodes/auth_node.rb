require 'dora/protocol/nodes/node'

module Dora
  module Protocol
    module Nodes
      class AuthNode < Node

        def initialize(number, auth_data)
          super('auth', {user: number, mechanism: 'WAUTH-2'}, nil, auth_data)
        end

      end
    end
  end
end

