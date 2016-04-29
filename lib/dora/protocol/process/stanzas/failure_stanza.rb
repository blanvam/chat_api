module Dora
  module Protocol
    module Process
      module Stanzas
        module FailureStanza

          def process_failure(node, *args)
            @conn.log_out
            if node.children.first.tag == 'not-authorized'
              logger.error('Blocked number or wrong password.')
            end
          end

        end
      end
    end
  end
end