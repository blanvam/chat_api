module Dora
  module Protocol
    module Identifiers

      private

      def iq_counter
        @iq_counter ||= 1
      end

      def message_id
        @message_id ||= random_hex(22)
      end

      def create_iq_id
        iq_id = @iq_counter
        @iq_counter += 1
        id = iq_id.to_s(16)
        if id.size % 2 == 1
          id = '0'+ id.size.to_s
        end
        id
      end

      def create_msg_id
        chars = hex2bin(@message_id).chars.map{|x| x.ord}
        pos = chars.size - 1
        while true do
          if chars[pos] < 255
            chars[pos] = chars[pos]+1
            break
          else
            chars[pos] = 0
            pos = pos-1
          end
        end
        msg = bin2hex(chars.map{|x| x.chr}.join)
        @message_id = msg
      end
    end
  end
end