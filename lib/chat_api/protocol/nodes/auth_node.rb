require 'chat_api/protocol/nodes/protocol_node'

module Dora
  module Protocol
    class AuthNode < ProtocolNode

      def initialize(number, auth_data)
        super('auth', {mechanism: 'WAUTH-2', user: number}, nil, auth_data)
      end

    end
  end
end