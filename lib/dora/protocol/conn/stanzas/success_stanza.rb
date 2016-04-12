module Dora
  module Protocol
    module Stanzas
      module SuccessStanza

        def process_success(node, *args)
          if node.attributes['status'] == 'active'
            log_in
            auth.write_data = node.data
            update_writer
          elsif node.attributes['status'] == 'expired'
          end
        end

      end
    end
  end
end