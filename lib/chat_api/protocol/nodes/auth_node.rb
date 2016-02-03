require 'chat_api/protocol/nodes/protocol_node'

module Dora
  module Protocol
    class AuthNode < ProtocolNode

      def initialize(number, auth_data)
        super('auth', {user: number, mechanism: 'WAUTH-2'}, nil, auth_data)
      end

    end
  end
end