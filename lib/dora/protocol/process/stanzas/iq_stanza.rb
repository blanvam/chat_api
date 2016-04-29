module Dora
  module Protocol
    module Process
      module Stanzas
        module IqStanza

          def process_iq(node, *args)
            if node.attributes['type'] == 'get' && node.attributes['xmlns'] == 'urn:xmpp:ping'
              send_pong(node.attributes['id'])
            end
            if node.attributes['type'] == 'result' && ( !node.get_child('media').nil? || !node.get_child('duplicate').nil? )
              process_upload_response(node, @auth.id)
            end
          end

        end
      end
    end
  end
end