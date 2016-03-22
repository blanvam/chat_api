module Dora
  module Stanzas
    module NotificationStanza

      def process_notification(node, *args)
        @cont.send_ack(node, node.tag)
      end

    end
  end
end