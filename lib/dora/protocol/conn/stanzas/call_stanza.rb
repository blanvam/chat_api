module Dora
  module Protocol
    module Stanzas
      module CallStanza

        def process_call(node, *args)
          if node.get_child(0).tag == 'offer'
            call_id = node.get_child(0).attributes['call-id']
            send_receipt(node, nil, nil, call_id)
          else
            send_ack(node, 'call')
          end
        end

      end
    end
  end
end