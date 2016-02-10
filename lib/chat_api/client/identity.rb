# encoding: utf-8
module Dora
  class Client
    # The Identify class define a identity used to register a number
    class Identity

      def initialize(jid, file = nil)
        file ||= File.join(Dora.data, DATA_FOLDER + "/id.#{jid}.dat")

        if File.exist?(file) && File.readable?(file)
          bytes = URI.unescape(open(file).read)
          length = bytes.length
          if length == 20 || length == 16
            @bytes = bytes
          end
        end

        unless @bytes
          @bytes = Random.new.bytes(20).downcase
          encode_bytes = URI::encode(@bytes)
          length = IO.write(file, encode_bytes)
          unless length == encode_bytes.length
            raise ChatAPIError('Unable to write identity file to ' + file);
          end
        end

      end

      def to_s
        @bytes.to_s
      end

    end
  end
end
