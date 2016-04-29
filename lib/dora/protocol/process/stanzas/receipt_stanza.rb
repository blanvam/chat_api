module Dora
  module Protocol
    module Process
      module Stanzas
        module ReceiptStanza

          @v_ten_only = {}

          def process_receipt(node, *args)
            if node.child? 'retry'
              send_get_cipher_keys_grom_user(JID.new(node.attributes('from')).number, true)
              #@message_store.set_pending(node.attributes['id'], node.attributes['from'])
            end
            if node.child?('error') && node.get_child('error').attributes['type'] == 'enc-v1'
              @v_ten_only[ExtractNumber(node.attributes['from'])] = true
              #@message_store.set_pending(node.attributes['id'], node.attributes['from']
              send_pending_messages node.attributes['from']
            end
            send_ack(node, node.tag)
          end

        end
      end
    end
  end
end