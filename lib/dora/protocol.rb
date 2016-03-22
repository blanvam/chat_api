module Dora
  module Protocol

    #nodes

    module Node
      autoload :AckNode,          'dora/protocol/node/ack_node'
      autoload :AuthNode,         'dora/protocol/node/auth_node'
      autoload :AuthResponseNode, 'dora/protocol/node/auth_response_node'
      autoload :ClearDirtyNode,   'dora/protocol/node/clear_dirty_node'
      autoload :FeatureNode,      'dora/protocol/node/features_node'
      autoload :IqNode,           'dora/protocol/node/iq_node'
      autoload :MessageNode,      'dora/protocol/node/message_node'
      autoload :PresenceNode,     'dora/protocol/node/presence_node'
      autoload :ProtocolNode,     'dora/protocol/node/protocol_node'
      autoload :ReceiptNode,      'dora/protocol/node/receipt_node'
      autoload :SyncNode,         'dora/protocol/node/sync_node'
    end

    autoload :BinTreeNodeReader,  'dora/protocol/bin_tree_node_reader'
    autoload :BinTreeNodeWriter,  'dora/protocol/bin_tree_node_writer'
    autoload :JID,                'dora/protocol/jid'
    autoload :Authentication,     'dora/protocol/authentication'
    autoload :Challenge,          'dora/protocol/challenge'
    autoload :KeyStream,          'dora/protocol/key_stream'
    autoload :Connection,         'dora/protocol/connection'

    include Node

  end
end
