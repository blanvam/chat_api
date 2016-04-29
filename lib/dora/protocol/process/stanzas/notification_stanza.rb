module Dora
  module Protocol
    module Process
      module Stanzas
        module NotificationStanza

          def process_notification(node, *args)
            send_ack(node, node.tag)
          end

        end
      end
    end
  end
end