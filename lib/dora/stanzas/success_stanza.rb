module Dora
  module Stanzas
    module SuccessStanza

      def process_success(node, *args)
        if node.attributes['status'] == 'active'
          @cont.log_in
          @cont.auth.write_data = node.data
          @cont.writer.set_key(@cont.auth.key_output)
        elsif node.attributes['status'] == 'expired'
        end
      end

    end
  end
end