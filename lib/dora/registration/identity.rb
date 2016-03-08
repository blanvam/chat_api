module Dora
  module Registration
    # The Identify class define a identity used to register a number
    class Identity

      attr_accessor :bytes

      def initialize(jid, file = nil)
        file ||= File.join(Dora.data, DATA_FOLDER + "/id.#{jid}.dat")

        process_file(file) if File.exist?(file) && File.readable?(file)
        get_bytes(file) unless @bytes
      end

      def to_s
        @bytes.to_s
      end

      private

      def process_file(file)
        bytes = URI.unescape(open(file).read)
        length = bytes.length
        @bytes = bytes if length == 20 || length == 16
      end

      def get_bytes(file)
        @bytes = Random.new.bytes(20).downcase
        encode_bytes = URI::encode(@bytes)
        length = IO.write(file, encode_bytes)
        unless length == encode_bytes.length
          fail ChatAPIError('Unable to write identity file to ' + file)
        end
      end

    end
  end
end
