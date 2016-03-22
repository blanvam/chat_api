module Dora
  module Stanzas
    module ChallengeStanza

      def process_challenge(node, *args)
        @cont.auth.data = node.data
      end

    end
  end
end