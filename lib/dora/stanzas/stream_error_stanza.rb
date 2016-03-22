module Dora
  module Stanzas
    module StreamErrorStanza

      def process_stream_error(*args)
        # Disconnect socket on stream error.
        @cont.disconnect
      end

    end
  end
end