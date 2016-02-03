
module Dora
  # Various utility functions
  module Util
    # Hex encodes a message
    #
    # @param [String] bytes The bytes to encode
    #
    # @return [String] Tasty, tasty hexadecimal
    def bin2hex(bytes)
      bytes.to_s.unpack('H*').first
    end

    # Hex decodes a message
    #
    # @param [String] hex hex to decode.
    #
    # @return [String] crisp and clean bytes
    def hex2bin(hex)
      [hex.to_s].pack('H*')
    end
  end
end
