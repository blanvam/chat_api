module Dora
  module Protocol
    module Process
      module Stanzas
        module MessageStanza

          def process_message(node, auto_receipt, type)
            @messages << node
            send_next_message if node.child?('x') && @last_id == node.attributes['id']
            if node.attributes['type'] == 'text' && !node.get_child('body').nil?
              author = node.attributes['participant']
              send_receipt(node, type, author) if auto_receipt
              if author == ''
                #private chat message
                #@message_store.save_message(extract_number(node.attributes('from')), @phone_number, node.get_child('body').data, node.attributes['id'], node.attributes['t']) unless @message_store.nil?
              else
                #group chat message
                #@message_store.save_message(author, node.attributes['from'], node.get_child('body').data, node.attributes['id'], node.attributes['t']) unless @message_store.nil?
              end
            end
            if node.attributes['type'] == 'media' && !node.get_child('media').nil?
              if node.get_child('media').attributes['type'] == 'image'
                send_iq_ack(node)
              end
              send_receipt(node, type) if auto_receipt
            end
            send_receipt(node, type) if auto_receipt && node.attributes['type'] == 'text' && node.get_child(0).tag == 'enc'
          end

          private

          def send_next_message
            if @out_queue.size > 0
              message_node = @out_queue.shift
              message_node.refresh_times
              @last_id = message_node.attributes['id']
              send_node(message_node)
            else
              @last_id = nil
            end
          end

        end
      end
    end
  end
end