module Dora
  module Protocol
    module Process
      module Stanzas
        module ChallengeStanza

          def process_challenge(node, *args)
            auth.data = node.data
          end

        end
      end
    end
  end
end