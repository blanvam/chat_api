require 'chat_api/protocol/nodes/protocol_node'

module Dora
  module Protocol
    class AuthResponseNode < ProtocolNode

      def initialize(auth_data)
        super('response', nil, nil, auth_data)
      end

    end
  end
end