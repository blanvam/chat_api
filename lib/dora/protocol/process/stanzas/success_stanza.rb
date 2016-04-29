module Dora
  module Protocol
    module Process
      module Stanzas
        module SuccessStanza

          def process_success(node, *args)
            if node.attributes['status'] == 'active'
              log_in
              auth.write_data = node.data
              update_writer(@auth.key_output)
            elsif node.attributes['status'] == 'expired'
            end
          end

        end
      end
    end
  end
end