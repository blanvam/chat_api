module Dora
  module Stanzas
    module CallStanza

      def process_call(node, *args)
        if node.get_child(0).tag == 'offer'
          call_id = node.get_child(0).attributes['call-id']
          @cont.send_receipt(node, nil, nil, call_id)
        else
          @cont.send_ack(node, 'call')
        end
      end

    end
  end
end