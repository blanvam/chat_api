require 'chat_api/protocol/nodes/protocol_node'

module Dora
  module Protocol
    class PresenceNode < ProtocolNode

      def initialize(attributes)
        super('presence', attributes)
      end

    end
  end
end