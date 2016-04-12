module Dora
  module Protocol
    module Nodes
      autoload :AckNode,          'dora/protocol/nodes/ack_node'
      autoload :AuthNode,         'dora/protocol/nodes/auth_node'
      autoload :AuthResponseNode, 'dora/protocol/nodes/auth_response_node'
      autoload :ClearDirtyNode,   'dora/protocol/nodes/clear_dirty_node'
      autoload :FeatureNode,      'dora/protocol/nodes/features_node'
      autoload :IqNode,           'dora/protocol/nodes/iq_node'
      autoload :MessageNode,      'dora/protocol/nodes/message_node'
      autoload :PresenceNode,     'dora/protocol/nodes/presence_node'
      autoload :Node,             'dora/protocol/nodes/node'
      autoload :ReceiptNode,      'dora/protocol/nodes/receipt_node'
      autoload :SyncNode,         'dora/protocol/nodes/sync_node'
    end
  end
end