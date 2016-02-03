require 'chat_api/protocol/nodes/protocol_node'

module Dora
  module Protocol
    class FeatureNode < ProtocolNode

      def initialize
        super('stream:features', nil, nil)
      end

    end
  end
end