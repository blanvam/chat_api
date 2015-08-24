require 'chat_api/protocol/nodes/protocol_node'

module Dora
  module Protocol
    class FeatureNode < ProtocolNode

      def initialize
        super('stream:features', nil, create_feature_nodes)
      end

      private

      def create_feature_nodes
        read_receipts = ProtocolNode.new('readreceipts')
        groups_v2 = ProtocolNode.new('groups_v2')
        privacy = ProtocolNode.new('privacy')
        presence_v2 = ProtocolNode.new('presence')

        [read_receipts, groups_v2, privacy, presence_v2]
      end

    end
  end
end