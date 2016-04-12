module Dora
  module Protocol
    module Stanzas
      module StreamErrorStanza

        def process_stream_error(*args)
          # Disconnect socket on stream error.
          disconnect
        end

      end
    end
  end
end