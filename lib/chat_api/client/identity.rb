# encoding: utf-8
module Dora
  class Client
    class Identity

      def initialize(jid, file = nil)
        if file.nil?
          file = File.join(Dora.data, DATA_FOLDER + "/id.#{jid}.dat")
        end

        if File.exist?(file) && File.readable?(file)
          bytes = URI.unescape(open(file).read)
          length = bytes.length
          if length == 20 || length == 16
            @bytes = bytes
          end
        end

        unless @bytes
          @bytes = Random.new.bytes(20).downcase
          length = IO.write(file, URI::encode(@bytes))
          unless length == URI::encode(@bytes).length
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
