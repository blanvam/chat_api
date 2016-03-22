require 'dora/stanzas/call_stanza'
require 'dora/stanzas/challenge_stanza'
require 'dora/stanzas/failure_stanza'
require 'dora/stanzas/ib_stanza'
require 'dora/stanzas/iq_stanza'
require 'dora/stanzas/message_stanza'
require 'dora/stanzas/notification_stanza'
require 'dora/stanzas/presence_stanza'
require 'dora/stanzas/receipt_stanza'
require 'dora/stanzas/stream_error_stanza'
require 'dora/stanzas/success_stanza'

module Dora
  class Stanza

    attr_accessor :bind

    def initialize(con)
      @cont = con
      @nodes = []
      @messages = []
      @bind = ProcessNode
      @timeout = nil
    end

    def get_nodes
      @nodes
    end

    def reset_nodes
      @nodes = []
    end

    def get_messages
      @messages
    end

    def reset_messages
      @messages = []
    end

    def time
      @timeout ||= Time.now
    end

    def restart
      @timeout = nil
    end

    def process_node(node, auto_receipt: true, type: 'read')
      @nodes << node
      @timeout = Time.now
      @server_received_id = node.id
      logger.debug_log(node.to_s('rx ')+"\n")
      process(node, auto_receipt, type)
      @bind.process(node)
      node
    end

    private

    # 'call', 'challenge', 'failure', 'ib', 'iq', 'message', 'notification',
    # 'presence', 'receipt', 'stream:error', 'success'

    include Stanzas::CallStanza
    include Stanzas::ChallengeStanza
    include Stanzas::FailureStanza
    include Stanzas::IbStanza
    include Stanzas::IqStanza
    include Stanzas::MessageStanza
    include Stanzas::NotificationStanza
    include Stanzas::PresenceStanza
    include Stanzas::ReceiptStanza
    include Stanzas::StreamErrorStanza
    include Stanzas::SuccessStanza

    # 'start', 'stream:features', 'ack', 'chatstate', 'from'
    TAGS = [:process_start, :process_stream_features, :process_ack, :process_chatstate, :process_from]

    def process(node, auto_receipt, type)
      method_name = node.tag.gsub(':', '_')
      send "process_#{method_name}", node, auto_receipt, type
    end

    def method_missing(method, *args)
      if TAGS.include? method
        true
      else
        raise ChatAPIError.new("Method: '#{method}' not implemented")
      end
    end

  end
end