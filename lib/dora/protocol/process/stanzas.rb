require 'dora/protocol/process/stanzas/call_stanza'
require 'dora/protocol/process/stanzas/challenge_stanza'
require 'dora/protocol/process/stanzas/failure_stanza'
require 'dora/protocol/process/stanzas/ib_stanza'
require 'dora/protocol/process/stanzas/iq_stanza'
require 'dora/protocol/process/stanzas/message_stanza'
require 'dora/protocol/process/stanzas/notification_stanza'
require 'dora/protocol/process/stanzas/presence_stanza'
require 'dora/protocol/process/stanzas/receipt_stanza'
require 'dora/protocol/process/stanzas/stream_error_stanza'
require 'dora/protocol/process/stanzas/success_stanza'

module Dora
  module Protocol
    module Process
      module Stanzas

        attr_accessor :bind, :messages, :nodes

        def bind
          @bind ||= ProcessNode
        end

        def messages
          @messages ||= []
        end

        def nodes
          @nodes ||= []
        end

        private

        def process_node(node, auto_receipt: true, type: 'read')
          nodes << node
          @timeout = Time.now
          @server_received_id = node.id
          logger.debug_log(node.to_s('rx ')+"\n")
          process(node, auto_receipt, type)
          bind.process(node)
          node
        end

        private

        # 'call', 'challenge', 'failure', 'ib', 'iq', 'message', 'notification',
        # 'presence', 'receipt', 'stream:error', 'success'

        include CallStanza
        include ChallengeStanza
        include FailureStanza
        include IbStanza
        include IqStanza
        include MessageStanza
        include NotificationStanza
        include PresenceStanza
        include ReceiptStanza
        include StreamErrorStanza
        include SuccessStanza

        # 'start', 'stream:features', 'ack', 'chatstate', 'from'
        TAGS = [:process_start, :process_stream_features, :process_ack, :process_chatstate, :process_from]
        #TAGS = [:start, :stream_features, :ack, :chatstate, :from]

        def process(node, auto_receipt, type)
          method_name = node.tag.gsub(':', '_')
          send "process_#{method_name}", node, auto_receipt, type
        end

        def method_missing(method_id, *arguments, &block)
          if method_id.to_s =~ /^process_[\w]+/

            self.class.send :define_method, method_id do
              puts "Method: '#{method_id}' not implemented"
            end
            self.send(method_id)
          else
            super
          end
        end

        def method_missing2(method, *args)
          if TAGS.include? method
            true
          elsif method.to_s.start_with? 'process_'
            raise ChatAPIError.new("Method: '#{method}' not implemented")
          else
            super
          end
        end

      end
    end
  end
end