module Dora
  module Protocol
    module Process
      module Stanzas
        module StreamErrorStanza

          def process_stream_error(*args)
            # Disconnect socket on stream error.
            disconnect if connected?
          end

        end
      end
    end
  end
end